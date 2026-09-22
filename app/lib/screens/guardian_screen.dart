import 'package:flutter/material.dart';

import '../widgets/anko_image.dart';
import 'anko_conversation_screen.dart';

class GuardianScreen extends StatefulWidget {
  const GuardianScreen({super.key});

  @override
  State<GuardianScreen> createState() => _GuardianScreenState();
}

class _GuardianScreenState extends State<GuardianScreen> {
  bool _showCoverage = false;
  bool _messageAcknowledged = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        key: const Key('guardian-screen'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 14, 14, 10),
            sliver: SliverToBoxAdapter(child: _buildHeader(context)),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverList.list(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _showInfo('空间完整度用于提示尚未补全的房间资料。'),
                    child: const Text('空间完整度 75% · 4 个房间'),
                  ),
                ),
                const SizedBox(height: 8),
                _buildMessageCard(),
                const SizedBox(height: 14),
                GuardianMapCard(
                  showCoverage: _showCoverage,
                  onCoverageChanged: () =>
                      setState(() => _showCoverage = !_showCoverage),
                  onEventTap: _showInfo,
                  onAnkoLongPress: _openConversation,
                ),
                const SizedBox(height: 18),
                const Center(
                  child: Text(
                    '交互演示 · 未连接摄像头，所有事件与数值均为示例',
                    style: TextStyle(color: Color(0xFFA0A9B5), fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Anko守护界面',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        HeaderButton(
          tooltip: '今日消息',
          icon: Icons.notifications_none_rounded,
          showBadge: true,
          onPressed: () => _showInfo('今日有 2 条待查看提醒。'),
        ),
        const SizedBox(width: 8),
        HeaderButton(
          tooltip: '家庭设置',
          icon: Icons.settings_outlined,
          onPressed: () => _showInfo('家庭设置将在下一阶段迁移。'),
        ),
      ],
    );
  }

  Widget _buildMessageCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 12, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '妈妈 17:42',
                    style: TextStyle(color: Color(0xFF8A9BAE)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _messageAcknowledged
                        ? '妈妈的心意，你已经收到啦。'
                        : '晚饭在冰箱第二层，回来热一下再吃。',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        setState(() => _messageAcknowledged = true),
                    icon: Icon(
                      _messageAcknowledged
                          ? Icons.favorite
                          : Icons.check_rounded,
                    ),
                    label: Text(_messageAcknowledged ? '已回复' : '收到啦'),
                  ),
                ],
              ),
            ),
            GestureDetector(
              key: const Key('message-anko'),
              onLongPress: _openConversation,
              child: const AnkoImage(size: 108),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _openConversation() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AnkoConversationScreen()),
    );
  }
}

class HeaderButton extends StatelessWidget {
  const HeaderButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.showBadge = false,
    super.key,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton.filledTonal(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon),
          style: IconButton.styleFrom(backgroundColor: Colors.white),
        ),
        if (showBadge)
          const Positioned(
            right: 9,
            top: 8,
            child: CircleAvatar(radius: 3, backgroundColor: Color(0xFF0876F9)),
          ),
      ],
    );
  }
}

class GuardianMapCard extends StatelessWidget {
  const GuardianMapCard({
    required this.showCoverage,
    required this.onCoverageChanged,
    required this.onEventTap,
    required this.onAnkoLongPress,
    super.key,
  });

  final bool showCoverage;
  final VoidCallback onCoverageChanged;
  final ValueChanged<String> onEventTap;
  final VoidCallback onAnkoLongPress;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFEDF2F7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Anko守护',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const Text(
              '4 个房间 · 与家保持连接',
              style: TextStyle(color: Color(0xFF8B99AA)),
            ),
            const SizedBox(height: 14),
            AspectRatio(
              aspectRatio: 0.86,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: HomeMapPainter(showCoverage)),
                    ),
                    Positioned(
                      left: 16,
                      top: 24,
                      child: MapEvent(
                        icon: Icons.check_circle_outline_rounded,
                        title: '跌倒记录',
                        subtitle: '昨日 · 已确认无碍',
                        onTap: () => onEventTap('跌倒记录：家人已确认现场无碍。'),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      top: 102,
                      child: MapEvent(
                        icon: Icons.pest_control_rodent_outlined,
                        title: '疑似小动物',
                        subtitle: '厨房 · 3 条合并',
                        warm: true,
                        onTap: () => onEventTap('厨房活动需要家人核实。'),
                      ),
                    ),
                    Positioned(
                      left: 118,
                      top: 188,
                      child: GestureDetector(
                        key: const Key('map-anko'),
                        behavior: HitTestBehavior.opaque,
                        onLongPress: onAnkoLongPress,
                        child: const AnkoImage(size: 78),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      bottom: 18,
                      child: MapEvent(
                        icon: Icons.inventory_2_outlined,
                        title: '门口有外卖',
                        subtitle: '18:12 · 待领取',
                        onTap: () => onEventTap('门口外卖仍待领取。'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.shield_outlined, color: Color(0xFF8292A4)),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    '2台在线 · 1处无监测',
                    style: TextStyle(color: Color(0xFF8292A4)),
                  ),
                ),
                TextButton.icon(
                  onPressed: onCoverageChanged,
                  icon: const Icon(Icons.layers_outlined),
                  label: Text(showCoverage ? '关闭覆盖' : '覆盖图层'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MapEvent extends StatelessWidget {
  const MapEvent({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.warm = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool warm;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: warm
          ? const Color(0xFFFFF8EA)
          : Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: warm ? const Color(0xFFAD7B38) : const Color(0xFF74869A),
              ),
              const SizedBox(width: 7),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF8B98A8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeMapPainter extends CustomPainter {
  const HomeMapPainter(this.showCoverage);

  final bool showCoverage;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(22),
    );
    canvas.drawRRect(outer, Paint()..color = const Color(0xFFDDE5EC));
    final padding = size.width * 0.045;
    final home = Rect.fromLTRB(
      padding,
      padding,
      size.width - padding,
      size.height - padding,
    );
    final wall = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7;
    canvas.drawRRect(
      RRect.fromRectAndRadius(home, const Radius.circular(12)),
      wall,
    );
    final vertical = home.left + home.width * 0.58;
    final horizontal = home.top + home.height * 0.61;
    canvas.drawLine(
      Offset(vertical, home.top),
      Offset(vertical, home.bottom),
      wall,
    );
    canvas.drawLine(
      Offset(home.left, horizontal),
      Offset(home.right, horizontal),
      wall,
    );

    _fillRoom(
      canvas,
      Rect.fromLTRB(home.left + 4, home.top + 4, vertical - 4, horizontal - 4),
      const Color(0xFFF3EFE8),
    );
    _fillRoom(
      canvas,
      Rect.fromLTRB(vertical + 4, home.top + 4, home.right - 4, horizontal - 4),
      const Color(0xFFF1F5F7),
    );
    _fillRoom(
      canvas,
      Rect.fromLTRB(
        vertical + 4,
        horizontal + 4,
        home.right - 4,
        home.bottom - 4,
      ),
      const Color(0xFFE8EEF5),
    );
    _fillRoom(
      canvas,
      Rect.fromLTRB(
        home.left + 4,
        horizontal + 4,
        vertical - 4,
        home.bottom - 4,
      ),
      const Color(0xFFEDE8DE),
    );

    if (showCoverage) {
      final coverage = Paint()
        ..color = const Color(0xFF0876F9).withValues(alpha: 0.12);
      canvas.drawCircle(
        Offset(home.left + home.width * 0.38, home.top + home.height * 0.38),
        size.width * 0.3,
        coverage,
      );
      canvas.drawCircle(
        Offset(home.right, home.bottom),
        size.width * 0.24,
        coverage,
      );
    }
    _drawLabel(canvas, '客厅', Offset(home.left + 12, home.top + 12));
    _drawLabel(canvas, '厨房', Offset(vertical + 12, home.top + 12));
    _drawLabel(canvas, '玄关', Offset(home.left + 12, horizontal + 12));
    _drawLabel(canvas, '卧室', Offset(vertical + 12, horizontal + 12));
  }

  void _fillRoom(Canvas canvas, Rect rect, Color color) {
    canvas.drawRect(rect, Paint()..color = color);
  }

  void _drawLabel(Canvas canvas, String label, Offset offset) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(color: Color(0xFF9AA5B0), fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant HomeMapPainter oldDelegate) =>
      oldDelegate.showCoverage != showCoverage;
}
