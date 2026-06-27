import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../game/sections.dart';
import '../state/game_state.dart';
import '../widgets/candy.dart';
import 'game_screen.dart';

/// The winding candy road map for a single world (section of levels).
class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({super.key, required this.section});

  final GameSection section;

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  static const double _spacing = 132;
  static const double _topPad = 64;
  static const double _botPad = 90;
  static const double _node = 66;

  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final state = GameScope.read(context);
      // Centre on the current level if it lives in this world.
      final local = state.unlocked - widget.section.start;
      if (local < 0 || local >= widget.section.count) return;
      final target =
          _topPad + local * _spacing - _scroll.position.viewportDimension / 2;
      _scroll.jumpTo(target.clamp(0, _scroll.position.maxScrollExtent));
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = GameScope.of(context);
    final s = widget.section;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              s.gradient.first.withValues(alpha: 0.35),
              AppColors.bg.last,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _header(s),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final n = s.count;
                    final amp = (width / 2 - _node / 2 - 18).clamp(0.0, 130.0);
                    final centerX = width / 2;
                    final points = <Offset>[
                      for (var i = 0; i < n; i++)
                        Offset(
                          centerX + amp * math.sin((s.start + i) * 0.9),
                          _topPad + i * _spacing,
                        ),
                    ];
                    final mapHeight = _topPad + (n - 1) * _spacing + _botPad;

                    return SingleChildScrollView(
                      controller: _scroll,
                      child: SizedBox(
                        width: width,
                        height: mapHeight,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(painter: _RoadPainter(points)),
                            ),
                            for (var i = 0; i < n; i++)
                              ..._nodeWidgets(
                                context,
                                state,
                                s.start + i,
                                points[i],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(GameSection s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Row(
        children: [
          CandyButton(
            color: AppColors.pill,
            shadow: AppColors.softPinkShadow,
            radius: 14,
            depth: 4,
            padding: EdgeInsets.zero,
            onTap: () => Navigator.of(context).pop(),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.chevron_left_rounded,
                color: AppColors.accent,
                size: 30,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(s.emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              s.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.heading,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _nodeWidgets(
    BuildContext context,
    GameState state,
    int globalIndex,
    Offset p,
  ) {
    final locked = !state.isUnlocked(globalIndex);
    final completed = state.starsFor(globalIndex) > 0;
    final current = globalIndex == state.unlocked && !locked;

    return [
      if (completed)
        Positioned(
          left: p.dx - 40,
          top: p.dy - _node / 2 - 22,
          width: 80,
          child: _StarRow(stars: state.starsFor(globalIndex)),
        ),
      if (current)
        Positioned(
          left: p.dx - _node / 2 - 12,
          top: p.dy - _node / 2 - 12,
          child: const _PulseRing(size: _node + 24),
        ),
      Positioned(
        left: p.dx - _node / 2,
        top: p.dy - _node / 2,
        child: _LevelNode(
          index: globalIndex,
          locked: locked,
          current: current,
          size: _node,
          onTap: locked
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GameScreen(level: globalIndex),
                  ),
                ),
        ),
      ),
    ];
  }
}

class _LevelNode extends StatelessWidget {
  const _LevelNode({
    required this.index,
    required this.locked,
    required this.current,
    required this.size,
    required this.onTap,
  });

  final int index;
  final bool locked;
  final bool current;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final gradient = locked
        ? AppColors.lockedCard
        : AppColors.levelCards[index % AppColors.levelCards.length];
    final shadow = locked
        ? AppColors.lockedShadow
        : AppColors.levelShadow[index % AppColors.levelShadow.length];

    return CandyButton(
      gradient: gradient,
      shadow: shadow,
      radius: size / 2,
      depth: 6,
      padding: EdgeInsets.zero,
      onTap: onTap ?? () {},
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: locked
              ? const Icon(Icons.lock_rounded, color: Colors.white, size: 26)
              : Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: current ? 24 : 22,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    shadows: const [
                      Shadow(color: Color(0x33000000), offset: Offset(0, 2)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.stars});
  final int stars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final earned = i < stars;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Transform.translate(
            offset: Offset(0, i == 1 ? -3 : 0),
            child: Text(
              earned ? '★' : '✩',
              style: TextStyle(
                fontSize: 18,
                color: earned
                    ? const Color(0xFFFFCE3D)
                    : const Color(0xFFD9C7E0),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _PulseRing extends StatefulWidget {
  const _PulseRing({required this.size});
  final double size;

  @override
  State<_PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<_PulseRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          return Opacity(
            opacity: (1 - t) * 0.7,
            child: Transform.scale(
              scale: 0.85 + t * 0.4,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accent, width: 4),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RoadPainter extends CustomPainter {
  _RoadPainter(this.points);
  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i], b = points[i + 1];
      final midY = (a.dy + b.dy) / 2;
      path.cubicTo(a.dx, midY, b.dx, midY, b.dx, b.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFE0B98C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 30
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFF6DEBE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final dashPaint = Paint()
      ..color = const Color(0xCCFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      const on = 10.0, off = 14.0;
      while (d < metric.length) {
        final seg = metric.extractPath(d, math.min(d + on, metric.length));
        canvas.drawPath(seg, dashPaint);
        d += on + off;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RoadPainter old) => old.points != points;
}
