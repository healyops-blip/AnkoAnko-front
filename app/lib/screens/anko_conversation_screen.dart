import 'package:flutter/material.dart';

import '../widgets/anko_conversation_panel.dart';

class AnkoConversationScreen extends StatelessWidget {
  const AnkoConversationScreen({super.key});

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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AnkoConversationPanel(
              onCollapse: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
    );
  }
}
