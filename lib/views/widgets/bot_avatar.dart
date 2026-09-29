import 'package:flutter/material.dart';

import '../../config/app_colors.dart';

/// The bot's sparkle icon on a gradient square.
class BotAvatar extends StatelessWidget {
  const BotAvatar({super.key, this.size = 30, this.glow = false});

  final double size;

  /// Adds a soft coloured shadow, used for the big welcome icon.
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          if (glow)
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: Icon(Icons.auto_awesome, color: Colors.white, size: size * 0.55),
    );
  }
}
