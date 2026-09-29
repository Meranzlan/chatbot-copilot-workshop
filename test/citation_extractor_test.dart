import 'dart:convert';
import 'dart:io';

import 'package:chatbot_copilot/models/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';

/// Real Copilot Studio replies captured over Direct Line (ids removed).
List<Map<String, dynamic>> _loadActivities() {
  final json = jsonDecode(
    File('test/fixtures/copilot_activities.json').readAsStringSync(),
  );
  return List<Map<String, dynamic>>.from(json['activities']);
}

void main() {
  final activities = _loadActivities();
  final botReplies = activities
      .where((a) => a['from']['role'] == 'bot')
      .map(ChatMessage.fromActivity)
      .toList();

  test('document citations get the real file name and quoted passage', () {
    final answer = botReplies[0];

    expect(answer.citations.map((c) => c.title), [
      'JAKIM 1.pdf',
      'JAKIM 3.pdf',
    ]);
    for (final citation in answer.citations) {
      expect(citation.isLinkable, isFalse);
      expect(citation.snippet, isNotEmpty);
      expect(citation.snippet, isNot(startsWith('.')));
    }
  });

  test('reference lines and [n] markers are removed from the text', () {
    final answer = botReplies[0];

    expect(answer.text, startsWith('Cara pengiraan fidyah'));
    expect(answer.text, contains('**Kaedah Pengiraan Fidyah**'));
    expect(answer.text, isNot(contains('cite:')));
    expect(answer.text, isNot(contains('[1]')));
    expect(answer.text, isNot(contains('​')));
  });

  test('markers glued with zero-width spaces are removed cleanly', () {
    final answer = botReplies[1];

    expect(answer.citations.map((c) => c.title), [
      'JAKIM 4.pdf',
      'JAKIM 3.pdf',
      'JAKIM 2.pdf',
    ]);
    expect(answer.text, endsWith('www.islam.gov.my.'));
  });

  test('internal "=Topic.Answer" messages come out empty', () {
    expect(botReplies[2].text, isEmpty);
  });

  test('web citations keep their URL and title', () {
    final message = ChatMessage.fromActivity({
      'type': 'message',
      'id': 'web-1',
      'from': {'role': 'bot'},
      'text':
          'Fidyah is paid per missed day [1].\n\n'
          '[1]: https://www.islam.gov.my "Portal Rasmi JAKIM"',
    });

    expect(message.text, 'Fidyah is paid per missed day.');
    expect(message.citations, hasLength(1));
    expect(message.citations.single.title, 'Portal Rasmi JAKIM');
    expect(message.citations.single.url, 'https://www.islam.gov.my');
  });
}
