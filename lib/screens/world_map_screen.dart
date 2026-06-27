import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../game/sections.dart';
import '../state/game_state.dart';
import '../widgets/candy.dart';
import 'game_screen.dart';

/// The winding candy road map for a single world, with animated nodes, a
/// flowing road, a bobbing "play here" marker and drifting background candy.
class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({super.key, required this.section});

  final GameSection section;

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen>
    with TickerProviderStateMixin {
  static const double _spacing = 132;
  static const double _topPad = 116; // room for the first node's PLAY tag
  static const double _botPad = 100;
  static const double _node = 66;

  final ScrollController _scroll = ScrollController();

  // Staggered node pop-in.
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  // Continuous loop: flowing road dashes, bobbing marker, twinkling stars.
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final state = GameScope.read(context);
      final local = state.unlocked - widget.section.start;
      if (local < 0 || local >= widget.section.count) return;
      final target =
          _topPad + local * _spacing - _scroll.position.viewportDimension / 2;
      _scroll.jumpTo(target.clamp(0, _scroll.position.maxScrollExtent));
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    _loop.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = GameScope.of(context);
    final s = widget.section;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    s.gradient.first.withValues(alpha: 0.4),
                    AppColors.bg.last,
                  ],
                ),
              ),
            ),
          ),
          const Positioned.fill(child: IgnorePointer(child: FloatingBubbles())),
          SafeArea(
            child: Column(
              children: [
                _header(s, state),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final n = s.count;
                      final amp = (width / 2 - _node / 2 - 18).clamp(
                        0.0,
                        130.0,
                      );
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
                        physics: const BouncingScrollPhysics(),
                        child: SizedBox(
                          width: width,
                          height: mapHeight,
                          child: Stack(
                            children: [
                              // Flowing road.
                              Positioned.fill(
                                child: AnimatedBuilder(
                                  animation: _loop,
                                  builder: (_, __) => CustomPaint(
                                    painter: _RoadPainter(points, _loop.value),
                                  ),
                                ),
                              ),
                              // Animated nodes.
                              Positioned.fill(
                                child: AnimatedBuilder(
                                  animation: Listenable.merge([
                                    _entrance,
                                    _loop,
                                  ]),
                                  builder: (_, __) => Stack(
                                    children: _nodes(state, s, points, n),
                                  ),
                                ),
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
        ],
      ),
    );
  }

  Widget _header(GameSection s, GameState state) {
    var done = 0, stars = 0;
    for (var l = s.start; l <= s.end; l++) {
      if (state.starsFor(l) > 0) done++;
      stars += state.starsFor(l);
    }
    final maxStars = s.count * 3;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      child: Row(
        children: [
          CandyButton(
            color: AppColors.pill,
            shadow: AppColors.softPinkShadow,
            radius: 16,
            depth: 4,
            padding: EdgeInsets.zero,
            onTap: () => Navigator.of(context).pop(),
            child: const SizedBox(
              width: 46,
              height: 46,
              child: Icon(
                Icons.chevron_left_rounded,
                color: AppColors.accent,
                size: 30,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: s.shadow.withValues(alpha: 0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: s.gradient,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: s.shadow.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        s.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'WORLD ${s.index + 1}',
                          style: TextStyle(
                            fontSize: 10,
                            height: 1.1,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: s.shadow,
                          ),
                        ),
                        Text(
                          s.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            height: 1.05,
                            fontWeight: FontWeight.w700,
                            color: AppColors.heading,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '★',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFFFFCE3D),
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$stars/$maxStars',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.heading,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$done/${s.count} done',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _nodes(
    GameState state,
    GameSection s,
    List<Offset> points,
    int n,
  ) {
    final widgets = <Widget>[];
    for (var i = 0; i < n; i++) {
      final global = s.start + i;
      final p = points[i];
      final locked = !state.isUnlocked(global);
      final completed = state.starsFor(global) > 0;
      final current = global == state.unlocked && !locked;

      // Staggered pop-in: 0..1 with a back-ease overshoot.
      final raw = ((_entrance.value * (n + 5) - i) / 5).clamp(0.0, 1.0);
      final appear = raw;
      final pop = Curves.easeOutBack.transform(raw);
      // Gentle bob for the current node, once it has popped in.
      final bob = current && appear > 0.95
          ? math.sin(_loop.value * 2 * math.pi) * 4
          : 0.0;

      if (completed) {
        widgets.add(
          Positioned(
            left: p.dx - 40,
            top: p.dy - _node / 2 - 22,
            width: 80,
            child: Opacity(
              opacity: appear,
              child: _StarRow(stars: state.starsFor(global), loop: _loop),
            ),
          ),
        );
      }

      if (current) {
        widgets.add(
          Positioned(
            left: p.dx - _node / 2 - 12,
            top: p.dy - _node / 2 - 12 + bob,
            child: Opacity(
              opacity: appear,
              child: const _PulseRing(size: _node + 24),
            ),
          ),
        );
        // Bobbing "PLAY" marker above the node.
        widgets.add(
          Positioned(
            left: p.dx - 40,
            top: p.dy - _node / 2 - 44 + bob,
            width: 80,
            child: Opacity(opacity: appear, child: const _PlayTag()),
          ),
        );
      }

      widgets.add(
        Positioned(
          left: p.dx - _node / 2,
          top: p.dy - _node / 2 + bob,
          child: Transform.scale(
            scale: pop.clamp(0.0, 1.1),
            child: Opacity(
              opacity: appear.clamp(0.0, 1.0),
              child: _LevelNode(
                index: global,
                locked: locked,
                current: current,
                size: _node,
                onTap: locked
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => GameScreen(level: global),
                        ),
                      ),
              ),
            ),
          ),
        ),
      );
    }
    return widgets;
  }
}

class _PlayTag extends StatelessWidget {
  const _PlayTag();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.pinkLight, AppColors.pink],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: AppColors.pinkShadow, offset: Offset(0, 3)),
            ],
          ),
          child: const Text(
            'PLAY',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -2),
          child: const Icon(
            Icons.arrow_drop_down_rounded,
            color: AppColors.pink,
            size: 22,
          ),
        ),
      ],
    );
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
  const _StarRow({required this.stars, required this.loop});
  final int stars;
  final Animation<double> loop;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final earned = i < stars;
        // Subtle staggered twinkle on earned stars.
        final tw = earned
            ? 1 + 0.12 * math.sin((loop.value * 2 * math.pi) + i * 1.6)
            : 1.0;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Transform.translate(
            offset: Offset(0, i == 1 ? -3 : 0),
            child: Transform.scale(
              scale: tw,
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
  _RoadPainter(this.points, this.phase);
  final List<Offset> points;
  final double phase;

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

    // Flowing dashed centre line.
    final dashPaint = Paint()
      ..color = const Color(0xCCFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const on = 10.0, off = 14.0;
    for (final metric in path.computeMetrics()) {
      var d = -phase * (on + off); // animate the dash offset
      while (d < metric.length) {
        final start = math.max(0.0, d);
        final end = math.min(d + on, metric.length);
        if (end > start) {
          canvas.drawPath(metric.extractPath(start, end), dashPaint);
        }
        d += on + off;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RoadPainter old) =>
      old.points != points || old.phase != phase;
}
