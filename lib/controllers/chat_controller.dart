import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../models/chat_message.dart';
import '../repository/api_client.dart';
import '../repository/chatbot_repository.dart';

/// The brain of the chat screen.
///
/// It keeps the conversation state, asks [ChatbotRepository] to talk to the
/// bot, and calls `notifyListeners()` whenever something changes so the
/// screen redraws.
class ChatController extends ChangeNotifier {
  ChatController({
    ChatbotRepository? repository,
    this.pollInterval = const Duration(seconds: 1),
  }) : _repository = repository ?? ChatbotRepository();

  final ChatbotRepository _repository;

  /// How often we ask Direct Line "anything new?".
  final Duration pollInterval;

  /// If the bot hasn't answered by then, unlock the input again.
  static const replyTimeout = Duration(seconds: 60);

  // ── State the screen reads ───────────────────────────────────────────────
  final List<ChatMessage> _messages = [];
  bool _isConnecting = false;
  bool _isConnected = false;
  bool _isBotReplying = false;
  String? _errorMessage;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isConnecting => _isConnecting;
  bool get isConnected => _isConnected;
  bool get isBotReplying => _isBotReplying;
  String? get errorMessage => _errorMessage;
  String get botName => AppConfig.botName;

  // ── Internal ─────────────────────────────────────────────────────────────
  /// Goes up by one for every new conversation, so a polling loop from an
  /// older conversation knows it should stop.
  int _session = 0;
  DateTime _replyDeadline = DateTime.now();
  bool _disposed = false;

  /// Steps 1 + 2: get a token, open a conversation, then start polling.
  /// Also used by the "New conversation" button.
  Future<void> startConversation() async {
    final session = ++_session;
    _messages.clear();
    _isConnecting = true;
    _isConnected = false;
    _isBotReplying = false;
    _errorMessage = null;
    _notify();

    try {
      await _repository.getToken();
      await _repository.startConversation();
      if (session != _session) return; // A newer conversation took over.
      _isConnected = true;
      _pollForReplies(session); // Runs in the background, no await.
    } catch (e) {
      if (session != _session) return;
      _errorMessage = _describe(e);
    }
    _isConnecting = false;
    _notify();
  }

  /// Step 3: show the user's message and send it to the bot.
  Future<void> sendUserMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || !_isConnected || _isBotReplying) return;

    _messages.add(ChatMessage.fromUser(trimmed));
    _isBotReplying = true;
    _replyDeadline = DateTime.now().add(replyTimeout);
    _errorMessage = null;
    _notify();

    try {
      await _repository.sendMessage(trimmed);
    } catch (e) {
      _isBotReplying = false;
      if (e is ApiException && e.isAuthError) _isConnected = false;
      _errorMessage = _describe(e);
      _notify();
    }
  }

  /// Step 4: every [pollInterval], ask for new bot replies.
  Future<void> _pollForReplies(int session) async {
    while (session == _session && !_disposed) {
      try {
        final replies = await _repository.getNewReplies();
        if (session != _session || _disposed) return;

        for (final reply in replies) {
          if (_alreadyShown(reply)) continue;
          _messages.add(reply);
          _isBotReplying = false;
          _notify();
        }
      } catch (e) {
        if (session != _session || _disposed) return;
        // Expired or rejected token: polling again won't help.
        if (e is ApiException && e.isAuthError) {
          _isConnected = false;
          _isBotReplying = false;
          _errorMessage = _describe(e);
          _notify();
          return;
        }
        // Anything else (e.g. a network blip): try again next time.
      }

      if (_isBotReplying && DateTime.now().isAfter(_replyDeadline)) {
        _isBotReplying = false;
        _errorMessage = '$botName did not reply. Try asking again.';
        _notify();
      }

      await Future.delayed(pollInterval);
    }
  }

  /// Direct Line can deliver the same reply twice, or echo the user's text.
  /// We only compare against the current turn (from the user's last message
  /// onwards), so the bot can still say the same thing in a later turn.
  bool _alreadyShown(ChatMessage reply) {
    if (_messages.any((m) => m.id == reply.id)) return true;
    final lastUserMessage = _messages.lastIndexWhere((m) => m.isUser);
    final currentTurn = _messages.skip(
      lastUserMessage < 0 ? 0 : lastUserMessage,
    );
    return currentTurn.any((m) => m.text == reply.text);
  }

  void clearError() {
    _errorMessage = null;
    _notify();
  }

  /// Turns the errors people hit most often into a next step.
  String _describe(Object error) {
    if (error is! ApiException) return 'Something went wrong: $error';
    if (error.isOffline) {
      return 'Can\'t reach Copilot Studio. Check your internet connection, '
          'then tap ↻ to try again.';
    }
    // Refused before the chat even started: usually a wrong or old URL.
    if (_isConnecting && error.statusCode >= 400) {
      return 'Copilot Studio refused to start a chat (${error.message}). '
          'Copy the token endpoint again from Copilot Studio → Channels → '
          'Mobile app into DIRECT_LINE_TOKEN_ENDPOINT in .env, then restart '
          'the app (R).';
    }
    if (error.isAuthError) {
      return 'Your session expired. Tap ↻ to start a new conversation.';
    }
    return error.message;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
