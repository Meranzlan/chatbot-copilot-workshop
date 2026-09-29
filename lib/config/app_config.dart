import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Which bot the app talks to. Values come from the `.env` file
/// (copy `.env.example` to `.env` to get started).
class AppConfig {
  /// Shown in the app bar, the typing indicator and the disclaimer.
  static String get botName => _read('BOT_NAME') ?? 'AI Assistant';

  /// Shown under the bot name.
  static const String poweredBy = 'Copilot Studio';

  /// Recommended. Copilot Studio hands out short-lived tokens from this URL,
  /// so no secret has to live inside the app.
  static String get tokenEndpoint => _read('DIRECT_LINE_TOKEN_ENDPOINT') ?? '';

  /// Fallback only. Anything bundled in an app can be extracted from it,
  /// so in a real app the secret stays on your own server.
  static String get directLineSecret => _read('DIRECT_LINE_SECRET') ?? '';

  static String get directLineBaseUrl =>
      _read('DIRECT_LINE_BASE_URL') ??
      'https://directline.botframework.com/v3/directline';

  static String? _read(String key) {
    final value = dotenv.isInitialized ? dotenv.maybeGet(key)?.trim() : null;
    return (value == null || value.isEmpty) ? null : value;
  }
}
