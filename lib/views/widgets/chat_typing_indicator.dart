import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../config/app_colors.dart';
import '../../config/demo_config.dart';
import 'bot_avatar.dart';

/// Shown at the bottom of the chat while we wait for the bot's reply.
class ChatTypingIndicator extends StatelessWidget {
  const ChatTypingIndicator({super.key, required this.botName});

  final String botName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const BotAvatar(),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.botBubble,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.botBubbleBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (DemoConfig.useSpinKitWave)
                  const SizedBox(
                    width: 24,
                    height: 14,
                    child: SpinKitWave(
                      color: AppColors.accent,
                      size: 14,
                      type: SpinKitWaveType.start,
                    ),
                  )
                else
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accent,
                    ),
                  ),
                if (DemoConfig.showTypingText) ...[
                  const SizedBox(width: 10),
                  Text(
                    '$botName is thinking...',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
