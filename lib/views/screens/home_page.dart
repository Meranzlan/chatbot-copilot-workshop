import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../controllers/chat_controller.dart';
import '../widgets/chat_app_bar.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_typing_indicator.dart';
import '../widgets/chat_welcome_view.dart';
import '../widgets/error_banner.dart';

/// The one and only screen: app bar, messages, input bar.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _chat = ChatController();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _chat.addListener(_scrollToBottom);
    _chat.startConversation();
  }

  @override
  void dispose() {
    _chat.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Sends [prompt] (from a suggestion card) or whatever is in the text field.
  void _send([String? prompt]) {
    final text = prompt ?? _textController.text;
    if (text.trim().isEmpty) return;
    if (prompt == null) _textController.clear();
    _chat.sendUserMessage(text);
  }

  void _scrollToBottom() {
    // Wait until the new message has been drawn, then scroll to it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Everything inside the builder is redrawn whenever the controller
    // calls notifyListeners().
    return ListenableBuilder(
      listenable: _chat,
      builder: (context, _) {
        return Scaffold(
          appBar: ChatAppBar(
            botName: _chat.botName,
            isConnected: _chat.isConnected,
            isConnecting: _chat.isConnecting,
            onRestart: _chat.startConversation,
          ),
          body: GestureDetector(
            // Tap anywhere outside the text field to hide the keyboard.
            onTap: () => FocusScope.of(context).unfocus(),
            child: SafeArea(
              child: Column(
                children: [
                  if (_chat.errorMessage != null)
                    ErrorBanner(
                      message: _chat.errorMessage!,
                      onClose: _chat.clearError,
                    ),
                  Expanded(child: _buildChatArea()),
                  ChatInputBar(
                    controller: _textController,
                    isReady: _chat.isConnected && !_chat.isBotReplying,
                    onSend: _send,
                    botName: _chat.botName,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatArea() {
    if (_chat.isConnecting) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.accent),
            const SizedBox(height: 20),
            Text(
              'Connecting to ${_chat.botName}...',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_chat.messages.isEmpty) {
      return ChatWelcomeView(onSelectPrompt: _send);
    }

    final messages = _chat.messages;
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      // One extra row at the end for the typing indicator.
      itemCount: messages.length + (_chat.isBotReplying ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length) {
          return ChatTypingIndicator(botName: _chat.botName);
        }
        return ChatMessageBubble(message: messages[index]);
      },
    );
  }
}
