import 'package:flutter/material.dart';

/// Every colour in the app, in one place.
/// Change a value here and hot reload (`r`) to restyle the whole app.
class AppColors {
  // Backgrounds and borders
  static const background = Color(0xFFF8F9FA);
  static const surface = Colors.white;
  static const border = Color(0xFFE1E3E1);

  // Text
  static const textPrimary = Color(0xFF1F1F1F);
  static const textSecondary = Color(0xFF444746);
  static const textMuted = Color(0xFF757575);
  static const textHint = Color(0xFFBDBDBD);

  // Brand
  static const primary = Color(0xFF2563EB);
  static const accent = Color(0xFF4285F4);
  static const brandGradient = LinearGradient(
    colors: [Color(0xFF4285F4), Color(0xFF9B72CB), Color(0xFFD96570)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const actionGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Chat bubbles
  static const userBubble = Color(0xFF2B3A67);
  static const botBubble = Color(0xFFF0F4F9);
  static const botBubbleBorder = Color(0xFFE1E7EE);
  static const codeBackground = Color(0xFFE3E8EF);

  // Connection status
  static const online = Color(0xFF137333);
  static const onlineBackground = Color(0xFFE6F4EA);
  static const connecting = Color(0xFFB06000);
  static const connectingBackground = Color(0xFFFEF7E0);
  static const error = Color(0xFFC5221F);
  static const errorBackground = Color(0xFFFCE8E6);

  // Citation chips
  static const webCitation = Color(0xFF2D358F);
  static const documentCitation = Color(0xFFB06000);
  static const documentCitationBackground = Color(0xFFFEF7E0);
}
