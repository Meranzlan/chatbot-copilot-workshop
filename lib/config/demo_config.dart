/// =============================================================================
/// LIVE DEMO FEATURE TOGGLES
///
/// Flip any value between `true` and `false`, then press `r` (Hot Reload)
/// to show a "before vs after" of that feature.
/// =============================================================================
class DemoConfig {
  /// 1. Web link citations: chips that open the source web page in the app.
  static const bool showCitationsURL = true;

  /// 2. Document citations: chips for uploaded files (PDF, Word…) that open
  /// the quoted passage the AI used.
  static const bool showCitationsPDF = true;

  /// 3. Timestamps (`10:46`) inside chat bubbles.
  static const bool showTimestamp = true;

  /// 4. "Copy" button on bot replies.
  static const bool showCopyButton = true;

  /// 5. 👍 / 👎 buttons on bot replies.
  static const bool showFeedbackActions = false;

  /// 6. Four suggested prompt cards on the empty welcome screen.
  static const bool showSuggestedPrompts = false;

  /// 7. "Powered by …" disclaimer under the input bar.
  static const bool showDisclaimerFooter = false;

  /// 8. Sparkle icon inside the input bar.
  static const bool showInputSparkle = false;

  /// 9. "AI Assistant is thinking..." label next to the typing animation.
  static const bool showTypingText = true;

  /// 10. Typing animation: `flutter_spinkit` wave (true) or Flutter's
  /// built-in spinner (false).
  static const bool useSpinKitWave = true;
}
