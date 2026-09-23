import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';

import '../data/guardian_map_repository.dart';
import '../domain/guardian_map_models.dart';
import '../widgets/anko_image.dart';
import 'anko_conversation_screen.dart';

class GuardianScreen extends StatefulWidget {
  const GuardianScreen({required this.repository, super.key});

  final GuardianMapRepository repository;

  @override
  State<GuardianScreen> createState() => _GuardianScreenState();
}

class _GuardianScreenState extends State<GuardianScreen> {
  bool _showCoverage = false;
  bool _messageAcknowledged = false;
  double _conversationPullDistance = 0;
  late Future<GuardianMapSnapshot> _mapFuture;

  @override
  void initState() {
    super.initState();
    _mapFuture = widget.repository.fetchMap();
  }

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
                _buildMessageCard(),
                const SizedBox(height: 14),
                _buildGuardianMap(),
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
    final pullProgress = (_conversationPullDistance / 110).clamp(0.0, 1.0);
    return Transform.translate(
      offset: Offset(0, pullProgress * 14),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 12, 10),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildConversationDragTarget(
                      key: const Key('message-card-drag-region'),
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
                  ),
                  _AnkoConversationTrigger(
                    key: const Key('message-anko'),
                    imageSize: 108,
                    touchSize: 116,
                    onLongPress: _openConversation,
                  ),
                ],
              ),
              _buildConversationDragTarget(
                child: SizedBox(
                  width: double.infinity,
                  child: Transform.translate(
                    offset: Offset(0, pullProgress * 4),
                    child: _PullDownConversationCue(progress: pullProgress),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuardianMap() {
    return FutureBuilder<GuardianMapSnapshot>(
      future: _mapFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _MapLoadError(
            message: snapshot.error.toString(),
            onRetry: () =>
                setState(() => _mapFuture = widget.repository.fetchMap()),
          );
        }
        if (snapshot.data case final map?) {
          return GuardianMapCard(
            map: map,
            showCoverage: _showCoverage,
            onCoverageChanged: () =>
                setState(() => _showCoverage = !_showCoverage),
            onEventTap: _showInfo,
            onAnkoLongPress: _openConversation,
          );
        }
        return const Card(
          child: SizedBox(
            height: 360,
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleConversationDragUpdate(DragUpdateDetails details) {
    setState(() {
      _conversationPullDistance = (_conversationPullDistance + details.delta.dy)
          .clamp(0, 140);
    });
  }

  Widget _buildConversationDragTarget({required Widget child, Key? key}) {
    return GestureDetector(
      key: key,
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: _handleConversationDragUpdate,
      onVerticalDragEnd: _handleConversationDragEnd,
      child: child,
    );
  }

  void _handleConversationDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final shouldOpen = velocity > 500 || _conversationPullDistance >= 110;
    setState(() => _conversationPullDistance = 0);
    if (shouldOpen) _openConversation();
  }

  void _openConversation() {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => const AnkoConversationScreen(),
        transitionDuration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 420),
        reverseTransitionDuration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 300),
        transitionsBuilder: (_, animation, _, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
              .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: child,
        ),
      ),
    );
  }
}

class _PullDownConversationCue extends StatelessWidget {
  const _PullDownConversationCue({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      Icons.keyboard_double_arrow_down_rounded,
      key: const Key('conversation-pull-cue'),
      size: 25 + progress * 3,
      color: Color.lerp(
        const Color(0xFF8CA5BD),
        const Color(0xFF0876F9),
        progress,
      ),
    );
    return Semantics(
      label: '下滑进入对话模式',
      child: MediaQuery.disableAnimationsOf(context)
          ? icon
          : icon
                .animate(
                  onPlay: (controller) =>
                      controller.repeat(reverse: true, count: 2),
                )
                .fade(begin: 0.35, end: 1, duration: 680.ms)
                .moveY(begin: -2, end: 3, curve: Curves.easeInOut)
                .shimmer(
                  delay: 120.ms,
                  duration: 560.ms,
                  color: const Color(0x99FFFFFF),
                ),
    );
  }
}

class _AnkoConversationTrigger extends StatelessWidget {
  const _AnkoConversationTrigger({
    required this.imageSize,
    required this.touchSize,
    required this.onLongPress,
    super.key,
  });

  final double imageSize;
  final double touchSize;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '长按 Anko 进入对话模式',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () {
          HapticFeedback.mediumImpact();
          onLongPress();
        },
        child: SizedBox.square(
          dimension: touchSize,
          child: Center(child: AnkoImage(size: imageSize)),
        ),
      ),
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
    required this.map,
    required this.showCoverage,
    required this.onCoverageChanged,
    required this.onEventTap,
    required this.onAnkoLongPress,
    super.key,
  });

  final GuardianMapSnapshot map;
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
            Text(
              '空间完整度 ${map.completionPercent}% · ${map.rooms.length} 个房间',
              style: const TextStyle(color: Color(0xFF8B99AA)),
            ),
            const SizedBox(height: 14),
            AspectRatio(
              aspectRatio: 0.86,
              child: _GuardianMapCanvas(
                map: map,
                showCoverage: showCoverage,
                onEventTap: onEventTap,
                onAnkoLongPress: onAnkoLongPress,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.shield_outlined, color: Color(0xFF8292A4)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${map.onlineDeviceCount}台在线 · '
                    '${map.unmonitoredRoomCount}处无监测',
                    style: const TextStyle(color: Color(0xFF8292A4)),
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

class _MapLoadError extends StatelessWidget {
  const _MapLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.map_outlined, size: 42),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: onRetry, child: const Text('重新加载地图')),
          ],
        ),
      ),
    );
  }
}

class _GuardianMapCanvas extends StatelessWidget {
  const _GuardianMapCanvas({
    required this.map,
    required this.showCoverage,
    required this.onEventTap,
    required this.onAnkoLongPress,
  });

  final GuardianMapSnapshot map;
  final bool showCoverage;
  final ValueChanged<String> onEventTap;
  final VoidCallback onAnkoLongPress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: HomeMapPainter(map, showCoverage)),
              ),
              for (final event in map.events) _positionEvent(event, size),
              _positionAnko(size),
            ],
          );
        },
      ),
    );
  }

  Widget _positionEvent(GuardianMapEvent event, Size size) {
    const markerWidth = 148.0;
    const markerHeight = 50.0;
    final left = (event.position.x * size.width - markerWidth / 2).clamp(
      4.0,
      size.width - markerWidth - 4,
    );
    final top = (event.position.y * size.height - markerHeight / 2).clamp(
      4.0,
      size.height - markerHeight - 4,
    );
    return Positioned(
      left: left,
      top: top,
      width: markerWidth,
      child: GuardianEventMarker(
        event: event,
        onTap: () => onEventTap('${event.title}：${event.subtitle}'),
      ),
    );
  }

  Widget _positionAnko(Size size) {
    const touchSize = 104.0;
    const imageSize = 78.0;
    final left = (map.ankoPosition.x * size.width - touchSize / 2).clamp(
      0.0,
      size.width - touchSize,
    );
    final top = (map.ankoPosition.y * size.height - touchSize / 2).clamp(
      0.0,
      size.height - touchSize,
    );
    return Positioned(
      left: left,
      top: top,
      child: _AnkoConversationTrigger(
        key: const Key('map-anko'),
        imageSize: imageSize,
        touchSize: touchSize,
        onLongPress: onAnkoLongPress,
      ),
    );
  }
}

class GuardianEventMarker extends StatelessWidget {
  const GuardianEventMarker({
    required this.event,
    required this.onTap,
    super.key,
  });

  final GuardianMapEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final warm = event.severity != GuardianEventSeverity.info;
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
                _iconFor(event.eventType),
                size: 20,
                color: warm ? const Color(0xFFAD7B38) : const Color(0xFF74869A),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      event.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF8B98A8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String eventType) {
    return switch (eventType) {
      'fallDetected' => Icons.check_circle_outline_rounded,
      'animalDetected' => Icons.pest_control_rodent_outlined,
      'deliveryDetected' => Icons.inventory_2_outlined,
      _ => Icons.notifications_none_rounded,
    };
  }
}

class HomeMapPainter extends CustomPainter {
  const HomeMapPainter(this.map, this.showCoverage);

  final GuardianMapSnapshot map;
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
    for (var index = 0; index < map.rooms.length; index++) {
      _drawRoom(canvas, home, map.rooms[index], index);
    }

    if (showCoverage) {
      final coverage = Paint()
        ..color = const Color(0xFF0876F9).withValues(alpha: 0.12);
      for (final device in map.devices.where((device) => device.online)) {
        canvas.drawCircle(
          _toCanvasPoint(home, device.position),
          home.width * device.coverageRadius,
          coverage,
        );
      }
    }
    for (final room in map.rooms) {
      _drawLabel(canvas, room.name, _toCanvasPoint(home, room.labelPosition));
    }
  }

  void _drawRoom(Canvas canvas, Rect home, GuardianRoom room, int index) {
    if (room.polygon.isEmpty) return;
    final path = Path();
    final first = _toCanvasPoint(home, room.polygon.first);
    path.moveTo(first.dx, first.dy);
    for (final point in room.polygon.skip(1)) {
      final offset = _toCanvasPoint(home, point);
      path.lineTo(offset.dx, offset.dy);
    }
    path.close();
    canvas
      ..drawPath(path, Paint()..color = _roomColor(room, index))
      ..drawPath(
        path,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeJoin = StrokeJoin.round,
      );
  }

  Color _roomColor(GuardianRoom room, int index) {
    if (room.privacyEnabled) return const Color(0xFFDDE3E9);
    if (room.monitoringStatus == RoomMonitoringStatus.unmonitored) {
      return const Color(0xFFE8EEF5);
    }
    if (room.scanStatus != RoomScanStatus.completed) {
      return const Color(0xFFEDE8DE);
    }
    const activeColors = [
      Color(0xFFF3EFE8),
      Color(0xFFF1F5F7),
      Color(0xFFEDE8DE),
    ];
    return activeColors[index % activeColors.length];
  }

  Offset _toCanvasPoint(Rect bounds, MapPoint point) {
    final x = point.x.clamp(0.0, 1.0);
    final y = point.y.clamp(0.0, 1.0);
    return Offset(
      bounds.left + bounds.width * x,
      bounds.top + bounds.height * y,
    );
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
      oldDelegate.map != map || oldDelegate.showCoverage != showCoverage;
}
