import 'package:chatbot_copilot/controllers/chat_controller.dart';
import 'package:chatbot_copilot/models/chat_message.dart';
import 'package:chatbot_copilot/repository/api_client.dart';
import 'package:chatbot_copilot/repository/chatbot_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stands in for Direct Line: hands out whatever replies the test queues up.
class FakeRepository implements ChatbotRepository {
  final List<ChatMessage> _queue = [];
  final List<String> sent = [];

  /// Set these to make the matching step fail.
  Object? tokenError;
  Object? sendError;
  Object? pollError;

  void queueReply(String id, String text) => _queue.add(
    ChatMessage(id: id, text: text, isUser: false, timestamp: DateTime.now()),
  );

  @override
  Future<void> getToken() async {
    if (tokenError != null) throw tokenError!;
  }

  @override
  Future<void> startConversation() async {}

  @override
  Future<void> sendMessage(String text) async {
    if (sendError != null) throw sendError!;
    sent.add(text);
  }

  @override
  Future<List<ChatMessage>> getNewReplies() async {
    if (pollError != null) throw pollError!;
    final replies = List<ChatMessage>.of(_queue);
    _queue.clear();
    return replies;
  }
}

void main() {
  late FakeRepository repository;
  late ChatController chat;

  // Give the background polling loop a few rounds to run.
  Future<void> letPollingRun() =>
      Future.delayed(const Duration(milliseconds: 30));

  setUp(() async {
    repository = FakeRepository();
    chat = ChatController(
      repository: repository,
      pollInterval: const Duration(milliseconds: 1),
    );
    await chat.startConversation();
  });

  tearDown(() => chat.dispose());

  test('shows the bot reply and unlocks the input', () async {
    await chat.sendUserMessage('Hello');
    expect(chat.isBotReplying, isTrue);

    repository.queueReply('a1', 'Hi! How can I help?');
    await letPollingRun();

    expect(chat.messages.map((m) => m.text), ['Hello', 'Hi! How can I help?']);
    expect(chat.isBotReplying, isFalse);
  });

  test('ignores the same reply delivered twice in one turn', () async {
    await chat.sendUserMessage('Hello');
    repository
      ..queueReply('a1', 'Hi!')
      ..queueReply('a1', 'Hi!') // same activity again
      ..queueReply('a2', 'Hi!'); // same text, new id
    await letPollingRun();

    expect(chat.messages.where((m) => !m.isUser), hasLength(1));
  });

  test('shows a repeated answer in a later turn', () async {
    // Copilot Studio often repeats lines like "Anything else?".
    await chat.sendUserMessage('First question');
    repository.queueReply('a1', 'Anything else?');
    await letPollingRun();

    await chat.sendUserMessage('Second question');
    repository.queueReply('a2', 'Anything else?');
    await letPollingRun();

    expect(chat.messages.where((m) => !m.isUser), hasLength(2));
    expect(chat.isBotReplying, isFalse);
  });

  test('a new conversation clears the old messages', () async {
    await chat.sendUserMessage('Hello');
    repository.queueReply('a1', 'Hi!');
    await letPollingRun();

    await chat.startConversation();

    expect(chat.messages, isEmpty);
    expect(chat.isConnected, isTrue);
  });

  group('error messages say what to do next', () {
    test('no internet', () async {
      repository.tokenError = ApiException(
        0,
        'No internet connection.',
        isOffline: true,
      );
      await chat.startConversation();

      expect(
        chat.errorMessage,
        'Can\'t reach Copilot Studio. Check your internet connection, then '
        'tap ↻ to try again.',
      );
    });

    test('token endpoint rejected while connecting', () async {
      repository.tokenError = ApiException(404, 'Not Found (HTTP 404)');
      await chat.startConversation();

      expect(chat.errorMessage, contains('DIRECT_LINE_TOKEN_ENDPOINT'));
      expect(chat.errorMessage, contains('HTTP 404'));
    });

    test('token expired while sending', () async {
      repository.sendError = ApiException(403, 'Token expired (HTTP 403)');
      await chat.sendUserMessage('Hello');

      expect(
        chat.errorMessage,
        'Your session expired. Tap ↻ to start a new conversation.',
      );
      expect(chat.isConnected, isFalse);
    });

    test('token expired while waiting for a reply', () async {
      await chat.sendUserMessage('Hello');
      repository.pollError = ApiException(403, 'Token expired (HTTP 403)');
      await letPollingRun();

      expect(
        chat.errorMessage,
        'Your session expired. Tap ↻ to start a new conversation.',
      );
      expect(chat.isConnected, isFalse);
      expect(chat.isBotReplying, isFalse);
    });

    test('anything unexpected', () async {
      repository.sendError = StateError('boom');
      await chat.sendUserMessage('Hello');

      expect(chat.errorMessage, 'Something went wrong: Bad state: boom');
    });
  });
}
