import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/app_colors.dart';
import '../../models/chat_citation.dart';
import '../../utils/open_link.dart';
import 'toast.dart';

/// A small numbered pill under a bot reply, showing one source.
/// Web sources open the page; documents open the quoted passage.
class CitationChip extends StatelessWidget {
  const CitationChip({super.key, required this.number, required this.citation});

  final int number;
  final ChatCitation citation;

  String get _title =>
      citation.title.isNotEmpty ? citation.title : 'Reference $number';

  Future<void> _onTap(BuildContext context) async {
    if (citation.isLinkable && await openLink(citation.url)) return;
    // A document, or a link that couldn't be opened: show the source instead.
    if (context.mounted) _showSource(context);
  }

  void _showSource(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _SourceSheet(
        title: _title,
        citation: citation,
        onCopied: (message) {
          Navigator.of(sheetContext).pop();
          showToast(context, message);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = citation.isLinkable
        ? AppColors.webCitation
        : AppColors.documentCitation;
    final background = citation.isLinkable
        ? AppColors.webCitation.withValues(alpha: 0.08)
        : AppColors.documentCitationBackground;
    final shortTitle = _title.length > 28
        ? '${_title.substring(0, 28)}…'
        : _title;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _onTap(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 9,
                backgroundColor: color,
                child: Text(
                  '$number',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                shortTitle,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                citation.isLinkable
                    ? Icons.open_in_new_rounded
                    : Icons.article_outlined,
                size: 12,
                color: color.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet showing a source's name and the passage the bot used.
class _SourceSheet extends StatelessWidget {
  const _SourceSheet({
    required this.title,
    required this.citation,
    required this.onCopied,
  });

  final String title;
  final ChatCitation citation;
  final ValueChanged<String> onCopied;

  @override
  Widget build(BuildContext context) {
    final isLink = citation.isLinkable;
    final body = citation.hasSnippet
        ? citation.snippet
        : isLink
        ? 'Source web link: ${citation.url}\n\nThe AI agent used this page to ground its answer.'
        : 'The AI agent used this document ($title) to ground its answer.';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.documentCitationBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isLink ? Icons.public_rounded : Icons.description_outlined,
                  size: 20,
                  color: AppColors.documentCitation,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      isLink ? 'Web source' : 'Knowledge document',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.documentCitation,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Flexible(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  body,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.6,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Source used by the AI',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: isLink ? citation.url : body),
                  );
                  onCopied(isLink ? 'Link copied' : 'Passage copied');
                },
                icon: const Icon(Icons.copy_rounded, size: 14),
                label: Text(
                  isLink ? 'Copy link' : 'Copy passage',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
