import 'package:flutter/material.dart';

import '../widgets/anko_image.dart';

class AnkoConversationScreen extends StatefulWidget {
  const AnkoConversationScreen({super.key});

  @override
  State<AnkoConversationScreen> createState() => _AnkoConversationScreenState();
}

class _AnkoConversationScreenState extends State<AnkoConversationScreen> {
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
    return Scaffold(
      key: const Key('anko-conversation-screen'),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.25),
            radius: 1.15,
            colors: [Color(0xFFD8EAFF), Color(0xFFF5F8FC)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              const Spacer(),
              const AnkoImage(size: 180),
              const SizedBox(height: 18),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _showTextChat
                        ? _buildTextChat()
                        : _buildVoiceControls(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: '返回守护界面',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          const Expanded(
            child: Text(
              '对话模式',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF5D83AA),
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildVoiceControls() {
    return Card(
      key: const ValueKey('voice-controls'),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isListening ? 'Anko 正在聆听' : '已暂停聆听',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(_isListening ? '轻点麦克风暂停' : '轻点麦克风继续'),
              const SizedBox(height: 16),
              _VoiceWave(active: _isListening),
              const SizedBox(height: 14),
              IconButton.filled(
                key: const Key('conversation-microphone'),
                onPressed: () => setState(() => _isListening = !_isListening),
                iconSize: 30,
                padding: const EdgeInsets.all(16),
                icon: Icon(
                  _isListening ? Icons.mic_rounded : Icons.mic_off_rounded,
                ),
              ),
              const SizedBox(height: 14),
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
        ),
      ),
    );
  }

  Widget _buildTextChat() {
    return Card(
      key: const ValueKey('text-chat'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                  return Align(
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
  const _VoiceWave({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    const activeHeights = [14.0, 28.0, 38.0, 28.0, 14.0];
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: activeHeights
            .map(
              (height) => AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 5,
                height: active ? height : 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0876F9)
                      .withValues(alpha: active ? 1 : 0.35),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _ConversationMessage {
  const _ConversationMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}
