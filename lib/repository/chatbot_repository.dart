import '../config/app_config.dart';
import '../models/chat_message.dart';
import 'api_client.dart';

/// Talks to a Copilot Studio agent through the Direct Line 3.0 REST API.
///
///   Step 1  getToken()           GET  DIRECT_LINE_TOKEN_ENDPOINT (from .env)
///   Step 2  startConversation()  POST /conversations
///   Step 3  sendMessage()        POST /conversations/{id}/activities
///   Step 4  getNewReplies()      GET  /conversations/{id}/activities?watermark=…
class ChatbotRepository {
  ChatbotRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  String? _token;
  String? _conversationId;

  /// Direct Line numbers every activity. The watermark remembers the last one
  /// we've read, so each poll only returns what's new.
  String? _watermark;

  /// Step 1: get a short-lived token.
  Future<void> getToken() async {
    if (AppConfig.tokenEndpoint.contains('<your-')) {
      throw ApiException(
        0,
        'DIRECT_LINE_TOKEN_ENDPOINT in .env is still the example from '
        '.env.example. Paste your agent\'s token endpoint (Copilot Studio → '
        'Channels → Mobile app), then restart the app (R).',
      );
    }

    final dynamic response;
    if (AppConfig.tokenEndpoint.isNotEmpty) {
      // Recommended: Copilot Studio gives us a token. No secret in the app.
      response = await _client.get(Uri.parse(AppConfig.tokenEndpoint));
    } else if (AppConfig.directLineSecret.isNotEmpty) {
      // Demo only: trade the secret for a token. In a real app this call
      // happens on your server, so the secret never ships inside the app.
      response = await _client.post(
        _url('tokens/generate'),
        token: AppConfig.directLineSecret,
      );
    } else {
      throw ApiException(
        0,
        'Add DIRECT_LINE_TOKEN_ENDPOINT to your .env file (see .env.example).',
      );
    }

    final token = response is Map ? response['token'] : null;
    if (token is! String) {
      throw ApiException(0, 'Could not get a token from Copilot Studio.');
    }
    _token = token;
  }

  /// Step 2: open a new conversation.
  Future<void> startConversation() async {
    final response = await _client.post(_url('conversations'), token: _token);
    _conversationId = response['conversationId'];
    _token = response['token'] ?? _token;
    _watermark = null;
  }

  /// Step 3: send what the user typed.
  Future<void> sendMessage(String text) async {
    await _client.post(
      _url('conversations/$_conversationId/activities'),
      token: _token,
      body: {
        'type': 'message',
        'from': {'id': 'user'},
        'text': text,
      },
    );
  }

  /// Step 4: fetch bot replies that arrived since the last call.
  Future<List<ChatMessage>> getNewReplies() async {
    final conversationId = _conversationId;
    final response = await _client.get(
      _url(
        'conversations/$conversationId/activities',
        _watermark == null ? null : {'watermark': _watermark!},
      ),
      token: _token,
    );

    // A new conversation started while we were waiting: drop this old answer.
    if (conversationId != _conversationId) return [];

    _watermark = response['watermark'] ?? _watermark;
    final List activities = response['activities'] ?? [];

    return activities
        // Only messages from the bot. Direct Line also sends back a copy of
        // every message the user sent, plus typing and event activities.
        .where((a) => a['type'] == 'message' && a['from']?['role'] == 'bot')
        .map((a) => ChatMessage.fromActivity(a))
        // Empty after cleaning, e.g. Copilot Studio's internal "=Topic.Answer".
        .where((message) => message.text.isNotEmpty)
        .toList();
  }

  Uri _url(String path, [Map<String, String>? query]) {
    final base = AppConfig.directLineBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final url = Uri.parse('$base/$path');
    return (query == null || query.isEmpty)
        ? url
        : url.replace(queryParameters: query);
  }
}
