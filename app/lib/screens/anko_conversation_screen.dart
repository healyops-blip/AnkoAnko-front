import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../widgets/anko_image.dart';

class AnkoConversationScreen extends StatefulWidget {
  const AnkoConversationScreen({super.key});

  @override
  State<AnkoConversationScreen> createState() => _AnkoConversationScreenState();
}

class _AnkoConversationScreenState extends State<AnkoConversationScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <_ConversationMessage>[
    const _ConversationMessage(
      text: '你好，我是 Anko。你可以直接告诉我发生了什么，或者问我家里的消息和守护情况。',
      isUser: false,
    ),
  ];
  bool _isResponding = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('anko-conversation-screen'),
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          key: const Key('close-conversation'),
          tooltip: '返回守护界面',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 30),
        ),
        titleSpacing: 4,
        title: const Row(
          children: [
            AnkoImage(size: 38),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Anko',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                Text(
                  '自然语言对话',
                  style: TextStyle(
                    color: Color(0xFF7D8FA2),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      key: const Key('conversation-message-list'),
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
      itemCount: _messages.length + (_isResponding ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) return const _ThinkingMessage();
        return _MessageBubble(message: _messages[index], index: index);
      },
    );
  }

  Widget _buildComposer() {
    return Material(
      color: Colors.white,
      elevation: 12,
      shadowColor: const Color(0x220D579B),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              tooltip: '语音输入',
              onPressed: () => _showVoiceComingSoon(context),
              icon: const Icon(Icons.graphic_eq_rounded),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                key: const Key('conversation-text-field'),
                controller: _messageController,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: '给 Anko 发消息',
                  filled: true,
                  fillColor: const Color(0xFFF2F5F8),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              key: const Key('send-conversation-message'),
              tooltip: '发送',
              onPressed: _isResponding ? null : _sendMessage,
              icon: const Icon(Icons.arrow_upward_rounded),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _messages.add(_ConversationMessage(text: message, isUser: true));
      _messageController.clear();
      _isResponding = true;
    });
    _scrollToLatestMessage();

    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() {
      _messages.add(
        const _ConversationMessage(
          text: '我听到了。你可以继续说，我会结合家庭消息和守护事件陪你一起处理。',
          isUser: false,
        ),
      );
      _isResponding = false;
    });
    _scrollToLatestMessage();
  }

  void _scrollToLatestMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _showVoiceComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('语音输入接口将在下一阶段接入')));
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.index});

  final _ConversationMessage message;
  final int index;

  @override
  Widget build(BuildContext context) {
    final bubble = Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            const AnkoImage(size: 34),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 310),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser ? const Color(0xFF0876F9) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(message.isUser ? 18 : 5),
                  bottomRight: Radius.circular(message.isUser ? 5 : 18),
                ),
                boxShadow: message.isUser
                    ? null
                    : const [
                        BoxShadow(
                          color: Color(0x0F183D61),
                          blurRadius: 14,
                          offset: Offset(0, 5),
                        ),
                      ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser
                      ? Colors.white
                      : const Color(0xFF27394B),
                  fontSize: 16,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
    if (MediaQuery.disableAnimationsOf(context)) return bubble;
    return bubble
        .animate()
        .fadeIn(duration: 220.ms, delay: (index * 45).ms)
        .moveY(begin: 10, end: 0, curve: Curves.easeOutCubic);
  }
}

class _ThinkingMessage extends StatelessWidget {
  const _ThinkingMessage();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 18),
      child: Row(
        children: [AnkoImage(size: 34), SizedBox(width: 10), _ThinkingDots()],
      ),
    );
  }
}

class _ThinkingDots extends StatelessWidget {
  const _ThinkingDots();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [_Dot(opacity: 0.35), _Dot(opacity: 0.65), _Dot(opacity: 1)],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.opacity});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF0876F9).withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ConversationMessage {
  const _ConversationMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}
