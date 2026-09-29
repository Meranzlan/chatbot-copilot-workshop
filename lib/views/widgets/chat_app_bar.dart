import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/app_config.dart';
import 'bot_avatar.dart';

/// Top bar: bot name, connection status and the "New conversation" button.
class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ChatAppBar({
    super.key,
    required this.botName,
    required this.isConnected,
    required this.isConnecting,
    required this.onRestart,
  });

  final String botName;
  final bool isConnected;
  final bool isConnecting;
  final VoidCallback onRestart;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 16,
      title: Row(
        children: [
          const BotAvatar(size: 36),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                botName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Text(
                AppConfig.poweredBy,
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
      actions: [
        _StatusPill(isConnected: isConnected, isConnecting: isConnecting),
        IconButton(
          tooltip: 'New conversation',
          icon: const Icon(
            Icons.refresh_rounded,
            color: AppColors.textSecondary,
          ),
          onPressed: isConnecting ? null : onRestart,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

/// "Online" / "Connecting" / "Offline" with a coloured dot.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isConnected, required this.isConnecting});

  final bool isConnected;
  final bool isConnecting;

  @override
  Widget build(BuildContext context) {
    String label = 'Offline';
    Color color = AppColors.error;
    Color background = AppColors.errorBackground;
    if (isConnecting) {
      label = 'Connecting';
      color = AppColors.connecting;
      background = AppColors.connectingBackground;
    } else if (isConnected) {
      label = 'Online';
      color = AppColors.online;
      background = AppColors.onlineBackground;
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 7, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
