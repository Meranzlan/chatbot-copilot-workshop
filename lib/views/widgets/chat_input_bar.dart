import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/app_config.dart';
import '../../config/demo_config.dart';

/// Rounded text field with a send button at the bottom of the screen.
class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.isReady,
    required this.onSend,
    required this.botName,
  });

  final TextEditingController controller;

  /// False while connecting or while the bot is replying.
  final bool isReady;
  final VoidCallback onSend;
  final String botName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.border, width: 1.2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (DemoConfig.showInputSparkle)
                  const Padding(
                    padding: EdgeInsets.only(left: 8, right: 8, bottom: 10),
                    child: Icon(
                      Icons.auto_awesome,
                      size: 20,
                      color: AppColors.textHint,
                    ),
                  )
                else
                  const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 1,
                    maxLines: 4,
                    style: const TextStyle(
                      fontSize: 14.5,
                      color: AppColors.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Ask anything...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: AppColors.textHint,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 10,
                      ),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
                // Rebuilds only the button as the user types, so it lights up
                // as soon as there is text to send.
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) {
                    final canSend = isReady && value.text.trim().isNotEmpty;
                    return Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: canSend ? AppColors.actionGradient : null,
                        color: canSend ? null : AppColors.border,
                      ),
                      child: IconButton(
                        tooltip: 'Send',
                        iconSize: 18,
                        onPressed: canSend ? onSend : null,
                        icon: Icon(
                          Icons.arrow_upward_rounded,
                          color: canSend ? Colors.white : AppColors.textHint,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          if (DemoConfig.showDisclaimerFooter) ...[
            const SizedBox(height: 6),
            Text(
              '$botName is powered by ${AppConfig.poweredBy}. AI responses may vary.',
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
