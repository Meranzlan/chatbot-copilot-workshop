import '../utils/citation_extractor.dart';
import 'chat_citation.dart';

export 'chat_citation.dart';

/// One bubble in the chat.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.citations = const [],
  });

  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  /// Sources the bot used for this answer (web pages or documents).
  final List<ChatCitation> citations;

  /// A message the user typed.
  factory ChatMessage.fromUser(String text) {
    final now = DateTime.now();
    return ChatMessage(
      id: 'user_${now.microsecondsSinceEpoch}',
      text: text,
      isUser: true,
      timestamp: now,
    );
  }

  /// A bot reply, built from a Direct Line activity (JSON).
  /// The text is cleaned up and its citations are pulled out.
  factory ChatMessage.fromActivity(Map<String, dynamic> activity) {
    final extracted = CitationExtractor.extract(activity);
    final sentAt = DateTime.tryParse(activity['timestamp']?.toString() ?? '');

    return ChatMessage(
      id:
          activity['id']?.toString() ??
          'bot_${DateTime.now().microsecondsSinceEpoch}',
      text: extracted.cleanedText,
      isUser: false,
      timestamp: sentAt?.toLocal() ?? DateTime.now(),
      citations: extracted.citations,
    );
  }
}
