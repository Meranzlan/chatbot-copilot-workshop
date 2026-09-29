import 'package:chatbot_copilot/config/app_colors.dart';
import 'package:chatbot_copilot/views/widgets/formatted_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Draws FormattedText and returns what it shows, split into styled pieces.
  Future<TextSpan> format(WidgetTester tester, String markdown) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FormattedText(markdown, style: const TextStyle(fontSize: 14)),
        ),
      ),
    );
    return tester.widget<SelectableText>(find.byType(SelectableText)).textSpan!;
  }

  TextSpan pieceOf(TextSpan text, String piece) => text.children!
      .cast<TextSpan>()
      .firstWhere(
        (span) => span.text == piece,
        orElse: () => fail('"$piece" is not shown as its own styled piece'),
      );

  TextStyle styleOf(TextSpan text, String piece) =>
      pieceOf(text, piece).style!;

  testWidgets('shows Markdown as formatting, not symbols', (tester) async {
    final text = await format(
      tester,
      '## Tips\n* **Bold** and *italic*\n- A dash item',
    );

    expect(text.toPlainText(), 'Tips\n• Bold and italic\n• A dash item');
    expect(styleOf(text, 'Tips').fontWeight, FontWeight.bold);
    expect(styleOf(text, 'Bold').fontWeight, FontWeight.bold);
    expect(styleOf(text, 'italic').fontStyle, FontStyle.italic);
  });

  testWidgets('shows source numbers like [1] as citation markers', (
    tester,
  ) async {
    final text = await format(tester, 'It came out in September. [1][2]');

    expect(text.toPlainText(), 'It came out in September. [1][2]');
    expect(styleOf(text, '[1]').color, AppColors.webCitation);
    expect(styleOf(text, '[2]').color, AppColors.webCitation);
  });

  testWidgets('shows `inline code` in a code font, without the backticks', (
    tester,
  ) async {
    final text = await format(
      tester,
      'Mark widgets `const`, and keep `a * b * c` as typed.',
    );

    // The asterisks inside code stay as typed instead of becoming italics.
    expect(
      text.toPlainText(),
      'Mark widgets const, and keep a * b * c as typed.',
    );
    expect(styleOf(text, 'const').fontFamily, 'monospace');
    expect(styleOf(text, 'a * b * c').fontFamily, 'monospace');
  });

  testWidgets('makes web links tappable, leaving punctuation outside', (
    tester,
  ) async {
    final text = await format(tester, 'See https://example.com/faq.');

    expect(text.toPlainText(), 'See https://example.com/faq.');
    final link = pieceOf(text, 'https://example.com/faq');
    expect(link.recognizer, isA<TapGestureRecognizer>());
    expect(link.style!.decoration, TextDecoration.underline);
  });

  testWidgets('does not turn a link inside `code` into a link', (
    tester,
  ) async {
    final text = await format(tester, 'Call `https://api.example.com/v1`');

    final code = pieceOf(text, 'https://api.example.com/v1');
    expect(code.recognizer, isNull);
    expect(code.style!.fontFamily, 'monospace');
  });
}
