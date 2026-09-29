import 'package:chatbot_copilot/models/chat_message.dart';
import 'package:chatbot_copilot/views/widgets/chat_message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('bot bubble shows formatted text and a document citation', (
    tester,
  ) async {
    final message = ChatMessage(
      id: 'bot-1',
      text: 'Fidyah is **RM4.00** per day.',
      isUser: false,
      timestamp: DateTime(2026, 1, 1, 10, 46),
      citations: const [
        ChatCitation(title: 'JAKIM 1.pdf', url: '', snippet: 'Kadar fidyah…'),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ChatMessageBubble(message: message)),
      ),
    );

    expect(find.textContaining('RM4.00', findRichText: true), findsOneWidget);
    expect(find.text('JAKIM 1.pdf'), findsOneWidget);

    // Tapping a document citation opens the quoted passage.
    await tester.tap(find.text('JAKIM 1.pdf'));
    await tester.pumpAndSettle();
    expect(find.text('Kadar fidyah…'), findsOneWidget);
  });
}
