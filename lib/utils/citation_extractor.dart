import '../models/chat_citation.dart';

/// Cleans a Copilot Studio reply and pulls out its citations.
/// You don't need to read this file to follow the chatbot flow.
class CitationExtractor {
  /// Extracts citations from a Direct Line activity by merging:
  /// 1. Text-embedded reference blocks: `[N]: cite:N "Title"` or `[N]: https://url "Title"`
  /// 2. The `entities` array where `@id == "cite:N"` holds the real tappable URL or text snippet.
  ///    Current Copilot Studio replies nest these under `citation[].appearance` (see below).
  /// 3. Fallbacks to `channelData.citations` if available.
  static ({String cleanedText, List<ChatCitation> citations}) extract(
    dynamic activity,
  ) {
    if (activity is! Map) {
      return (cleanedText: '', citations: <ChatCitation>[]);
    }

    String rawText = (activity['text'] ?? '').toString();

    // Strip default disclaimer string if present
    const disclaimer = 'AI-generated content may be incorrect';
    rawText = rawText.replaceAll(disclaimer, '').trim();

    final citationMap = <int, ChatCitation>{};

    // Build a comprehensive map of ID / Title → (title, url, snippet) from activity.entities
    final entityById = <String, ({String title, String url, String snippet})>{};
    final entities = activity['entities'];
    if (entities is List) {
      for (int i = 0; i < entities.length; i++) {
        final entity = entities[i];
        if (entity is Map) {
          final type = (entity['type'] ?? entity['@type'] ?? '')
              .toString()
              .toLowerCase();
          final rawId = (entity['@id'] ?? entity['id'] ?? '').toString().trim();

          final isCitationEntity =
              type.contains('citation') ||
              type.contains('claim') ||
              type.contains('message') ||
              type.contains('creativework') ||
              rawId.startsWith('cite:') ||
              entity.containsKey('citation') ||
              entity.containsKey('claim');

          if (isCitationEntity || rawId.isNotEmpty) {
            Map? nestedCitation;
            if (entity['citation'] is List &&
                (entity['citation'] as List).isNotEmpty) {
              final first = (entity['citation'] as List).first;
              if (first is Map) nestedCitation = first;
            } else if (entity['citation'] is Map) {
              nestedCitation = entity['citation'] as Map;
            }

            Map? nestedClaim;
            if (entity['claim'] is Map) {
              nestedClaim = entity['claim'] as Map;
            }

            // 1. Resolve Title
            String title =
                (nestedCitation?['name'] ??
                        nestedCitation?['title'] ??
                        nestedClaim?['name'] ??
                        nestedClaim?['title'] ??
                        entity['name'] ??
                        entity['title'] ??
                        '')
                    .toString()
                    .trim();

            // 2. Resolve URL
            String url =
                (nestedCitation?['url'] ??
                        nestedCitation?['contentUrl'] ??
                        nestedCitation?['contentLocation'] ??
                        nestedClaim?['url'] ??
                        entity['url'] ??
                        entity['contentUrl'] ??
                        entity['contentLocation'] ??
                        entity['target'] ??
                        '')
                    .toString()
                    .trim();

            // 3. Resolve Snippet (check nested first, then outer text/content)
            String snippet =
                (nestedCitation?['text'] ??
                        nestedCitation?['content'] ??
                        nestedCitation?['description'] ??
                        nestedCitation?['abstract'] ??
                        nestedCitation?['snippet'] ??
                        nestedClaim?['text'] ??
                        nestedClaim?['content'] ??
                        entity['text'] ??
                        entity['content'] ??
                        entity['description'] ??
                        entity['abstract'] ??
                        entity['snippet'] ??
                        entity['passage'] ??
                        '')
                    .toString()
                    .trim();

            final data = (title: title, url: url, snippet: snippet);

            // Index by all conceivable keys
            if (rawId.isNotEmpty) {
              entityById[rawId] = data;
              entityById[rawId.toLowerCase()] = data;
              if (rawId.startsWith('cite:')) {
                final suffix = rawId.substring(5).trim();
                entityById[suffix] = data;
                entityById[suffix.toLowerCase()] = data;
              }
            }

            final fallbackNum = (i + 1).toString();
            entityById['cite:$fallbackNum'] ??= data;
            entityById[fallbackNum] ??= data;

            if (title.isNotEmpty) {
              entityById[title] ??= data;
              entityById[title.toLowerCase()] ??= data;
            }
          }
        }
      }

      // Current Copilot Studio format (checked against live replies): one
      // "Message" entity whose `citation` list holds a Claim per source, with
      // the file name and quoted passage one level down in `appearance`:
      //   {"type": "https://schema.org/Message", "citation": [
      //     {"@type": "Claim", "position": 1,
      //      "appearance": {"name": "JAKIM 1.pdf", "text": "…passage…"}}]}
      // `position` matches the N in `[N]: cite:N`.
      for (final entity in entities) {
        final claims = entity is Map ? entity['citation'] : null;
        if (claims is! List) continue;
        for (final claim in claims) {
          if (claim is! Map || claim['appearance'] is! Map) continue;
          final position = (claim['position'] ?? '').toString();
          if (position.isEmpty) continue;
          final appearance = claim['appearance'] as Map;
          final data = (
            title: (appearance['name'] ?? appearance['title'] ?? '')
                .toString()
                .trim(),
            url: (appearance['url'] ?? '').toString().trim(),
            snippet: (appearance['text'] ?? appearance['abstract'] ?? '')
                .toString()
                .replaceFirst(RegExp(r'^[\s.,;:]+'), '')
                .trim(),
          );
          entityById['cite:$position'] = data;
          entityById[position] = data;
        }
      }
    }

    // Parse reference-style blocks from text: [N]: <ref> "Optional Title"
    final refPattern = RegExp(
      r'^\[(\d+)\]:\s*(\S+)(?:\s+"([^"]*)")\s*$',
      multiLine: true,
    );

    for (final match in refPattern.allMatches(rawText)) {
      final index = int.tryParse(match.group(1) ?? '') ?? 0;
      if (index <= 0) continue;

      final rawRef = (match.group(2) ?? '').trim();
      final textTitle = (match.group(3) ?? '').trim();

      // Look up matching entity
      final entityData =
          entityById[rawRef] ??
          entityById[rawRef.toLowerCase()] ??
          entityById['cite:$index'] ??
          entityById['$index'] ??
          entityById[textTitle] ??
          entityById[textTitle.toLowerCase()];

      final resolvedUrl = entityData?.url.isNotEmpty == true
          ? entityData!.url
          : (rawRef.startsWith('cite:') ? '' : rawRef);

      String resolvedTitle = '';
      if (entityData?.title.isNotEmpty == true &&
          !entityData!.title.startsWith('cite:')) {
        resolvedTitle = entityData.title;
      } else if (textTitle.isNotEmpty && !textTitle.startsWith('cite:')) {
        resolvedTitle = textTitle;
      } else {
        resolvedTitle = 'Reference $index';
      }

      final resolvedSnippet = entityData?.snippet ?? '';

      citationMap[index] = ChatCitation(
        title: resolvedTitle,
        url: resolvedUrl,
        snippet: resolvedSnippet,
      );
    }

    // Resolve orphan [N] markers: appear in raw text but have NO definition block.
    final allMarkers = RegExp(r'\[(\d+)\]')
        .allMatches(rawText)
        .map((m) => int.tryParse(m.group(1) ?? '') ?? 0)
        .where((n) => n > 0)
        .toSet();
    final definedIndexes = citationMap.keys.toSet();
    final orphans = allMarkers.difference(definedIndexes);
    if (orphans.isNotEmpty) {
      final entityList = entityById.values.toSet().toList();
      for (final orphanIdx in (orphans.toList()..sort())) {
        final entityData =
            entityById['cite:$orphanIdx'] ??
            entityById['$orphanIdx'] ??
            (orphanIdx <= entityList.length ? entityList[orphanIdx - 1] : null);

        if (entityData != null) {
          citationMap[orphanIdx] = ChatCitation(
            title: entityData.title.isNotEmpty
                ? entityData.title
                : 'Reference $orphanIdx',
            url: entityData.url,
            snippet: entityData.snippet,
          );
        }
      }
    }

    // Fallback: if no citations in text map, use entities directly
    if (citationMap.isEmpty && entityById.isNotEmpty) {
      int idx = 1;
      final uniqueEntities = entityById.values.toSet();
      for (final e in uniqueEntities) {
        if (e.url.isNotEmpty || e.title.isNotEmpty || e.snippet.isNotEmpty) {
          citationMap[idx++] = ChatCitation(
            title: e.title.isNotEmpty ? e.title : 'Reference $idx',
            url: e.url,
            snippet: e.snippet,
          );
        }
      }
    }

    // Fallback: channelData.citations
    if (citationMap.isEmpty) {
      final channelData = activity['channelData'];
      if (channelData is Map) {
        final rawCitations = channelData['citations'];
        if (rawCitations is List) {
          int idx = 1;
          for (final c in rawCitations) {
            if (c is Map) {
              final title = (c['title'] ?? c['name'] ?? '').toString().trim();
              final url =
                  (c['url'] ?? c['contentUrl'] ?? c['contentLocation'] ?? '')
                      .toString()
                      .trim();
              final snippet =
                  (c['content'] ?? c['text'] ?? c['description'] ?? '')
                      .toString()
                      .trim();
              if (url.isNotEmpty || title.isNotEmpty || snippet.isNotEmpty) {
                citationMap[idx++] = ChatCitation(
                  title: title.isNotEmpty ? title : 'Reference $idx',
                  url: url,
                  snippet: snippet,
                );
              }
            }
          }
        }
      }
    }

    // Clean the message text
    String cleaned = rawText.replaceAll(refPattern, '').trim();
    // Markers can be glued with zero-width spaces: "[1]​[2]".
    cleaned = cleaned.replaceAll(RegExp(r'(\[\d+\]​?)+'), '').trim();
    cleaned = cleaned.replaceAll(RegExp(r'[ \t]+\.'), '.').trim();

    // Collect normalized citation URLs
    final inlineUrlPattern = RegExp(
      r'https?://[^\s]+|www\.[^\s]+',
      caseSensitive: false,
    );
    final citationUrlBases = citationMap.values
        .where((c) => c.isLinkable)
        .map(
          (c) => c.url
              .toLowerCase()
              .replaceFirst(RegExp(r'^https?://'), '')
              .replaceFirst(RegExp(r'^www\.'), ''),
        )
        .where((s) => s.isNotEmpty)
        .toSet();

    // Remove entire trailing paragraph blocks that contain a citation URL
    if (citationUrlBases.isNotEmpty) {
      bool lineHasCitationUrl(String line) {
        for (final m in inlineUrlPattern.allMatches(line)) {
          final found = m
              .group(0)!
              .toLowerCase()
              .replaceFirst(RegExp(r'^https?://'), '')
              .replaceFirst(RegExp(r'^www\.'), '');
          for (final base in citationUrlBases) {
            if (found.contains(base) || base.contains(found)) return true;
          }
        }
        return false;
      }

      final lines = cleaned.split('\n');
      final outputLines = <String>[];
      final paraBuffer = <String>[];

      void flushPara() {
        if (paraBuffer.isEmpty) return;
        final hasCitationUrl = paraBuffer.any(lineHasCitationUrl);
        if (!hasCitationUrl) outputLines.addAll(paraBuffer);
        paraBuffer.clear();
      }

      for (final line in lines) {
        if (line.trim().isEmpty) {
          flushPara();
          outputLines.add('');
        } else {
          paraBuffer.add(line);
        }
      }
      flushPara();

      cleaned = outputLines.join('\n');
    }

    // Remove standalone Power Fx formula expressions (e.g. =Topic.Answer, =Topic.Output)
    cleaned = cleaned
        .replaceAll(
          RegExp(
            r'^\s*=(Topic|System|Global|User|bot)\.\w+\s*$',
            multiLine: true,
            caseSensitive: false,
          ),
          '',
        )
        .trim();

    // Collapse 3+ consecutive newlines to 2, then trim
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
    cleaned = cleaned.replaceAll(RegExp(r'[\n\s]+$'), '').trim();

    // If the entire text was just a Power Fx variable leak, return empty
    if (cleaned.startsWith('=') &&
        RegExp(
          r'^=(Topic|System|Global|User|bot)\.',
          caseSensitive: false,
        ).hasMatch(cleaned)) {
      return (cleanedText: '', citations: <ChatCitation>[]);
    }

    final sortedKeys = citationMap.keys.toList()..sort();
    return (
      cleanedText: cleaned,
      citations: sortedKeys
          .map((k) => citationMap[k]!)
          .where((c) => c.isLinkable || c.hasSnippet || c.title.isNotEmpty)
          .toList(),
    );
  }
}
