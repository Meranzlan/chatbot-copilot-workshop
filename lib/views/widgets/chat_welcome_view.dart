import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/demo_config.dart';
import 'bot_avatar.dart';

/// Greeting shown before the first message, with optional prompt cards.
class ChatWelcomeView extends StatelessWidget {
  const ChatWelcomeView({super.key, required this.onSelectPrompt});

  /// Called with the prompt text when a suggestion card is tapped.
  final ValueChanged<String> onSelectPrompt;

  static const _suggestions = [
    (
      icon: '💡',
      title: 'Brainstorm ideas',
      prompt: 'Help me brainstorm innovative ideas for my project.',
    ),
    (
      icon: '✍️',
      title: 'Draft a message',
      prompt: 'Draft a clear and professional follow-up email.',
    ),
    (
      icon: '🔍',
      title: 'Explain a concept',
      prompt: 'Explain how modern AI chatbots work in simple terms.',
    ),
    (
      icon: '⚡',
      title: 'Quick summary',
      prompt: 'What are key best practices for software architecture?',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            const BotAvatar(size: 56, glow: true),
            const SizedBox(height: 20),
            // Paints the text with a gradient instead of a single colour.
            ShaderMask(
              shaderCallback: AppColors.actionGradient.createShader,
              child: const Text(
                'Hello,',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'How can I help you today?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ask questions, draft messages, summarize information, or explore ideas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
            if (DemoConfig.showSuggestedPrompts) ...[
              const SizedBox(height: 24),
              for (final suggestion in _suggestions)
                _SuggestionCard(
                  icon: suggestion.icon,
                  title: suggestion.title,
                  prompt: suggestion.prompt,
                  onTap: () => onSelectPrompt(suggestion.prompt),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.icon,
    required this.title,
    required this.prompt,
    required this.onTap,
  });

  final String icon;
  final String title;
  final String prompt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Text(icon, style: const TextStyle(fontSize: 20)),
        title: Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          prompt,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 12,
          color: AppColors.textHint,
        ),
      ),
    );
  }
}
