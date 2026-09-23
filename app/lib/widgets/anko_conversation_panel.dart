import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'anko_image.dart';

class AnkoConversationPanel extends StatefulWidget {
  const AnkoConversationPanel({this.onCollapse, super.key});

  final VoidCallback? onCollapse;

  @override
  State<AnkoConversationPanel> createState() => _AnkoConversationPanelState();
}

class _AnkoConversationPanelState extends State<AnkoConversationPanel> {
  final _messageController = TextEditingController();
  final List<_ConversationMessage> _messages = const [
    _ConversationMessage(text: '想聊什么？我在。', isUser: false),
  ].toList();
  bool _showTextChat = false;
  bool _isListening = true;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    const anko = AnkoImage(size: 108);
    return DecoratedBox(
      key: const Key('anko-inline-conversation'),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF4FF), Color(0xFFF9FBFE)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD6E7FA)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 4),
            reduceMotion
                ? anko
                : anko
                      .animate()
                      .fadeIn(duration: 280.ms)
                      .moveY(begin: 12, end: 0, curve: Curves.easeOutCubic)
                      .scaleXY(begin: 0.92, end: 1),
            const SizedBox(height: 8),
            Expanded(
              child: AnimatedSwitcher(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.06, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _showTextChat
                    ? _buildTextChat(reduceMotion)
                    : _buildVoiceControls(reduceMotion),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const SizedBox(width: 40),
        const Expanded(
          child: Column(
            children: [
              SizedBox(
                width: 38,
                child: Divider(thickness: 4, color: Color(0xFFB8C9DB)),
              ),
              Text(
                '对话模式',
                style: TextStyle(
                  color: Color(0xFF5D83AA),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 40,
          child: widget.onCollapse == null
              ? null
              : IconButton(
                  key: const Key('collapse-conversation'),
                  tooltip: '收起对话',
                  onPressed: widget.onCollapse,
                  icon: const Icon(Icons.keyboard_arrow_up_rounded),
                ),
        ),
      ],
    );
  }

  Widget _buildVoiceControls(bool reduceMotion) {
    return Container(
      key: const ValueKey('voice-controls'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x110D579B),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _isListening ? 'Anko 正在聆听' : '已暂停聆听',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(_isListening ? '轻点麦克风暂停' : '轻点麦克风继续'),
          const SizedBox(height: 12),
          _VoiceWave(active: _isListening, reduceMotion: reduceMotion),
          const SizedBox(height: 10),
          DecoratedBox(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Color(0x330876F9), blurRadius: 18),
                  ],
                ),
                child: IconButton.filled(
                  key: const Key('conversation-microphone'),
                  onPressed: () => setState(() => _isListening = !_isListening),
                  iconSize: 28,
                  padding: const EdgeInsets.all(14),
                  icon: Icon(
                    _isListening ? Icons.mic_rounded : Icons.mic_off_rounded,
                  ),
                ),
              )
              .animate(
                target: _isListening && !reduceMotion ? 1 : 0,
                onPlay: (controller) => controller.repeat(reverse: true),
              )
              .scaleXY(
                begin: 1,
                end: 1.07,
                duration: 900.ms,
                curve: Curves.easeInOut,
              ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () => setState(() => _showTextChat = true),
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text('进入对话框模式'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextChat(bool reduceMotion) {
    return Container(
      key: const ValueKey('text-chat'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _showTextChat = false),
              icon: const Icon(Icons.mic_none_rounded),
              label: const Text('返回语音模式'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final bubble = Align(
                  alignment: message.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: message.isUser
                          ? const Color(0xFF0876F9)
                          : const Color(0xFFEDF4FD),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      message.isUser ? message.text : 'Anko：${message.text}',
                      style: TextStyle(
                        color: message.isUser
                            ? Colors.white
                            : const Color(0xFF4F6780),
                      ),
                    ),
                  ),
                );
                if (reduceMotion) return bubble;
                return bubble
                    .animate()
                    .fadeIn(duration: 220.ms, delay: (index * 60).ms)
                    .moveX(begin: message.isUser ? 14 : -14, end: 0);
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('conversation-text-field'),
                  controller: _messageController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: const InputDecoration(
                    hintText: '和 Anko 说点什么',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: '发送',
                onPressed: _sendMessage,
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    setState(() {
      _messages
        ..add(_ConversationMessage(text: message, isUser: true))
        ..add(const _ConversationMessage(text: '我在，慢慢说。', isUser: false));
      _messageController.clear();
    });
  }
}

class _VoiceWave extends StatelessWidget {
  const _VoiceWave({required this.active, required this.reduceMotion});

  final bool active;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    const heights = [18.0, 30.0, 40.0, 30.0, 18.0];
    return SizedBox(
      height: 42,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < heights.length; index++)
            _buildBar(index, heights[index]),
        ],
      ),
    );
  }

  Widget _buildBar(int index, double height) {
    final bar = Container(
      width: 5,
      height: active ? height : 7,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF0876F9).withValues(alpha: active ? 1 : 0.35),
        borderRadius: BorderRadius.circular(4),
      ),
    );
    if (!active || reduceMotion) return bar;
    return bar
        .animate(
          delay: (index * 90).ms,
          onPlay: (controller) => controller.repeat(reverse: true),
        )
        .scaleY(
          begin: 0.45,
          end: 1,
          duration: (520 + index * 70).ms,
          curve: Curves.easeInOut,
        );
  }
}

class _ConversationMessage {
  const _ConversationMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}
