import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../game/levels.dart';
import '../state/game_state.dart';
import '../widgets/candy.dart';
import 'game_screen.dart';

/// A Candy-Crush-style winding road map of levels: nodes sway left/right along
/// a curving candy path, showing stars / locks, with the current level marked.
class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  static const double _spacing = 132;
  static const double _topPad = 70;
  static const double _botPad = 90;
  static const double _node = 66;

  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    // Centre the map on the player's current level once laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final state = GameScope.read(context);
      final target =
          _topPad +
          state.unlocked * _spacing -
          _scroll.position.viewportDimension / 2;
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

    return Scaffold(
      body: CandyBackground(
        bubbles: false,
        child: Column(
          children: [
            _header(state),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final n = kLevels.length;
                  final amp = (width / 2 - _node / 2 - 18).clamp(0.0, 130.0);
                  final centerX = width / 2;
                  final points = <Offset>[
                    for (var i = 0; i < n; i++)
                      Offset(
                        centerX + amp * math.sin(i * 0.9),
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
                            ..._nodeWidgets(context, state, i, points[i]),
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
    );
  }

  Widget _header(GameState state) {
    final total = state.progress.fold<int>(0, (s, v) => s + v);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
          const Text(
            'Level Map',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.heading,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.pill,
              borderRadius: BorderRadius.circular(40),
              boxShadow: const [
                BoxShadow(color: AppColors.pillShadow, offset: Offset(0, 3)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⭐', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  '$total',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.heading,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _nodeWidgets(
    BuildContext context,
    GameState state,
    int i,
    Offset p,
  ) {
    final locked = !state.isUnlocked(i);
    final completed = state.starsFor(i) > 0;
    final current = i == state.unlocked && !locked;

    return [
      // Stars above completed nodes.
      if (completed)
        Positioned(
          left: p.dx - 40,
          top: p.dy - _node / 2 - 22,
          width: 80,
          child: _StarRow(stars: state.starsFor(i)),
        ),
      // Pulsing ring on the current level.
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
          index: i,
          locked: locked,
          current: current,
          size: _node,
          onTap: locked
              ? null
              : () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => GameScreen(level: i))),
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
                    fontSize: current ? 30 : 26,
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

/// Soft pulsing ring drawn behind the current level node.
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

/// Draws the winding candy road connecting the level nodes.
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

    // Road outline + fill.
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

    // Dashed white centre line.
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
