import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/app_colors.dart';
import '../../config/demo_config.dart';
import '../../models/chat_message.dart';
import 'bot_avatar.dart';
import 'citation_chip.dart';
import 'formatted_text.dart';
import 'toast.dart';

/// One chat message: a dark bubble on the right for the user,
/// a light bubble with the bot's avatar on the left for the bot.
class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return message.isUser ? _UserBubble(message) : _BotBubble(message);
  }
}

String _formatTime(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

class _UserBubble extends StatelessWidget {
  const _UserBubble(this.message);

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.userBubble,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(6),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                height: 1.4,
              ),
            ),
            if (DemoConfig.showTimestamp) ...[
              const SizedBox(height: 4),
              Text(
                _formatTime(message.timestamp),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BotBubble extends StatelessWidget {
  const _BotBubble(this.message);

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    // Hide the citation types that are switched off in DemoConfig.
    final citations = message.citations
        .where(
          (c) => c.isLinkable
              ? DemoConfig.showCitationsURL
              : DemoConfig.showCitationsPDF,
        )
        .toList();

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.88,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2, right: 10),
              child: BotAvatar(),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.botBubble,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      border: Border.all(color: AppColors.botBubbleBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FormattedText(
                          message.text,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14.5,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _BotMessageFooter(message),
                      ],
                    ),
                  ),
                  if (citations.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (int i = 0; i < citations.length; i++)
                          CitationChip(number: i + 1, citation: citations[i]),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Timestamp on the left; 👍 👎 and "Copy" on the right.
class _BotMessageFooter extends StatefulWidget {
  const _BotMessageFooter(this.message);

  final ChatMessage message;

  @override
  State<_BotMessageFooter> createState() => _BotMessageFooterState();
}

class _BotMessageFooterState extends State<_BotMessageFooter> {
  bool? _liked; // null = no vote, true = 👍, false = 👎

  void _vote(bool liked) {
    setState(() => _liked = _liked == liked ? null : liked);
    if (_liked == true) {
      showToast(context, 'Thank you for your feedback! 👍');
    } else if (_liked == false) {
      showToast(context, 'Feedback received! We will improve.');
    }
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.message.text));
    showToast(context, 'Copied to clipboard');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (DemoConfig.showTimestamp)
          Text(
            _formatTime(widget.message.timestamp),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
          ),
        const Spacer(),
        if (DemoConfig.showFeedbackActions) ...[
          _FooterButton(
            icon: _liked == true
                ? Icons.thumb_up_rounded
                : Icons.thumb_up_alt_outlined,
            color: _liked == true ? AppColors.primary : AppColors.textMuted,
            onTap: () => _vote(true),
          ),
          _FooterButton(
            icon: _liked == false
                ? Icons.thumb_down_rounded
                : Icons.thumb_down_alt_outlined,
            color: _liked == false ? AppColors.error : AppColors.textMuted,
            onTap: () => _vote(false),
          ),
          const SizedBox(width: 4),
        ],
        if (DemoConfig.showCopyButton)
          _FooterButton(
            icon: Icons.copy_rounded,
            label: 'Copy',
            color: AppColors.textMuted,
            onTap: _copy,
          ),
      ],
    );
  }
}

class _FooterButton extends StatelessWidget {
  const _FooterButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.label,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            if (label != null) ...[
              const SizedBox(width: 4),
              Text(
                label!,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
