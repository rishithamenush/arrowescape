import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../game/sections.dart';
import '../state/game_state.dart';
import '../widgets/candy.dart';
import 'world_map_screen.dart';

/// The "Worlds" overview, presented as a single winding candy **journey trail**:
/// each world is a glossy island stop along a flowing path, zig-zagging down the
/// screen. Tapping a stop opens that world's level map. This mirrors the in-game
/// road map so the whole app reads as one continuous adventure.
class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scroll = ScrollController();
  late final List<GameSection> _sections = buildSections();

  // Continuous loop for the flowing road dots + current-stop pulse.
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  // Trail geometry.
  static const double _spacing = 158; // vertical gap between stops
  static const double _topPad = 86;
  static const double _botPad = 96;
  static const double _node = 92; // island diameter

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final state = GameScope.read(context);
      final current = state.unlocked ~/ kSectionSize;
      final target =
          _topPad + current * _spacing - _scroll.position.viewportDimension / 2;
      _scroll.jumpTo(target.clamp(0, _scroll.position.maxScrollExtent));
    });
  }

  @override
  void dispose() {
    _loop.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = GameScope.of(context);
    return Scaffold(
      body: CandyBackground(
        child: Column(
          children: [
            _header(state),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final n = _sections.length;
                  final amp = (width / 2 - _node / 2 - 30).clamp(0.0, 96.0);
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
                    physics: const BouncingScrollPhysics(),
                    child: SizedBox(
                      width: width,
                      height: mapHeight,
                      child: AnimatedBuilder(
                        animation: _loop,
                        builder: (_, __) => Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _TrailPainter(points, _loop.value),
                              ),
                            ),
                            ..._stops(state, points),
                          ],
                        ),
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

  // ---------- header ----------
  Widget _header(GameState state) {
    final total = state.progress.fold<int>(0, (s, v) => s + v);
    final maxStars = state.progress.length * 3;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
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
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShaderMask(
                          shaderCallback: (rect) => const LinearGradient(
                            colors: [Color(0xFFFF7AB0), AppColors.accent],
                          ).createShader(rect),
                          child: const Text(
                            'Worlds',
                            style: TextStyle(
                              fontSize: 26,
                              height: 1,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 1),
                        const Text(
                          'Follow the trail to play',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFFFD76B), Color(0xFFFFB020)],
                      ),
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFFD77A1E),
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '★',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$total/$maxStars',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- stops ----------
  List<Widget> _stops(GameState state, List<Offset> points) {
    final widgets = <Widget>[];
    final centerX = MediaQuery.sizeOf(context).width / 2;
    for (var i = 0; i < _sections.length; i++) {
      final s = _sections[i];
      final p = points[i];
      final unlocked = state.isUnlocked(s.start);

      var completed = 0, stars = 0;
      for (var l = s.start; l <= s.end; l++) {
        if (state.starsFor(l) > 0) completed++;
        stars += state.starsFor(l);
      }
      final maxStars = s.count * 3;
      final perfected = completed == s.count && stars == maxStars;
      final isCurrent = state.unlocked >= s.start && state.unlocked <= s.end;
      final progress = s.count == 0 ? 0.0 : completed / s.count;
      final pulse = 0.5 + 0.5 * math.sin(_loop.value * 2 * math.pi);

      // Pulsing glow ring behind the current world.
      if (isCurrent) {
        const halo = 150.0;
        widgets.add(
          Positioned(
            left: p.dx - halo / 2,
            top: p.dy - halo / 2,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.35 + 0.35 * pulse,
                child: Container(
                  width: halo,
                  height: halo,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        s.shadow.withValues(alpha: 0.55),
                        s.shadow.withValues(alpha: 0),
                      ],
                      stops: const [0.25, 1],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      // The island stop.
      widgets.add(
        Positioned(
          left: p.dx - _node / 2,
          top: p.dy - _node / 2,
          child: _IslandStop(
            section: s,
            unlocked: unlocked,
            perfected: perfected,
            progress: progress,
            diameter: _node,
            onTap: unlocked
                ? () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WorldMapScreen(section: s),
                    ),
                  )
                : null,
          ),
        ),
      );

      // "PLAYING" pin above the current world.
      if (isCurrent) {
        widgets.add(
          Positioned(
            left: p.dx - 38,
            top: p.dy - _node / 2 - 30 - 3 * pulse,
            width: 76,
            child: const IgnorePointer(child: Center(child: _PlayPin())),
          ),
        );
      }

      // Name + stars label to the OPEN side of the island (right of left-side
      // stops, left of right-side stops) so it never crowds the road / next
      // node. Vertically centred on the island.
      const labelW = 150.0;
      final onLeft = p.dx < centerX - 1;
      final labelLeft = onLeft
          ? p.dx + _node / 2 - 6
          : p.dx - _node / 2 + 6 - labelW;
      widgets.add(
        Positioned(
          left: labelLeft,
          top: p.dy - 26,
          width: labelW,
          child: Align(
            alignment: onLeft ? Alignment.centerLeft : Alignment.centerRight,
            child: _StopLabel(
              section: s,
              unlocked: unlocked,
              stars: stars,
              maxStars: maxStars,
            ),
          ),
        ),
      );
    }
    return widgets;
  }
}

/// A glossy circular "island" for one world, with a progress ring, emoji, and
/// lock / crown states.
class _IslandStop extends StatefulWidget {
  const _IslandStop({
    required this.section,
    required this.unlocked,
    required this.perfected,
    required this.progress,
    required this.diameter,
    required this.onTap,
  });

  final GameSection section;
  final bool unlocked;
  final bool perfected;
  final double progress;
  final double diameter;
  final VoidCallback? onTap;

  @override
  State<_IslandStop> createState() => _IslandStopState();
}

class _IslandStopState extends State<_IslandStop> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.section;
    final d = widget.diameter;
    final grad = widget.unlocked ? s.gradient : AppColors.lockedCard;
    final shadow = widget.unlocked ? s.shadow : AppColors.lockedShadow;

    return GestureDetector(
      onTapDown: widget.onTap != null
          ? (_) => setState(() => _down = true)
          : null,
      onTapUp: widget.onTap != null
          ? (_) => setState(() => _down = false)
          : null,
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.93 : 1,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: SizedBox(
          width: d,
          height: d,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Progress ring.
              CustomPaint(
                size: Size(d, d),
                painter: _RingPainter(
                  progress: widget.unlocked ? widget.progress : 0,
                ),
              ),
              // Island body.
              Container(
                width: d - 16,
                height: d - 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: grad,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.75),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: shadow.withValues(alpha: 0.55),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  // Locked worlds stay a mystery — hide the themed emoji and
                  // show only a lock until the world is unlocked.
                  child: widget.unlocked
                      ? Text(s.emoji, style: const TextStyle(fontSize: 34))
                      : const Icon(
                          Icons.lock_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                ),
              ),
              // Glossy top highlight.
              Positioned(
                top: 12,
                child: IgnorePointer(
                  child: Container(
                    width: d * 0.42,
                    height: d * 0.22,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.55),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // World number badge (unlocked only — locked stays a mystery).
              if (widget.unlocked)
                Positioned(
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      '${s.index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: shadow,
                      ),
                    ),
                  ),
                ),
              // Crown for a fully-perfected world.
              if (widget.perfected)
                Positioned(
                  top: -14,
                  child: Text('👑', style: TextStyle(fontSize: 22)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Readable white pill under each island: world name + star count (or "Locked").
class _StopLabel extends StatelessWidget {
  const _StopLabel({
    required this.section,
    required this.unlocked,
    required this.stars,
    required this.maxStars,
  });

  final GameSection section;
  final bool unlocked;
  final int stars;
  final int maxStars;

  @override
  Widget build(BuildContext context) {
    final s = section;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Locked worlds keep their name hidden so the theme stays a surprise.
          Text(
            unlocked ? s.name : 'Locked',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.1,
              fontWeight: FontWeight.w800,
              color: unlocked ? s.shadow : AppColors.muted,
            ),
          ),
          const SizedBox(height: 1),
          if (unlocked)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '★',
                  style: TextStyle(fontSize: 12, color: Color(0xFFFFB020)),
                ),
                const SizedBox(width: 3),
                Text(
                  '$stars/$maxStars',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.body,
                  ),
                ),
              ],
            )
          else
            Text(
              'Unlock at level ${s.start + 1}',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
        ],
      ),
    );
  }
}

/// A little "PLAY" pin (teardrop marker) that hovers over the current world.
class _PlayPin extends StatelessWidget {
  const _PlayPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.pinkLight, AppColors.pink],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.pinkShadow,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
              SizedBox(width: 2),
              Text(
                'PLAY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        // Tail.
        Transform.translate(
          offset: const Offset(0, -1),
          child: CustomPaint(
            size: const Size(12, 7),
            painter: _PinTailPainter(),
          ),
        ),
      ],
    );
  }
}

class _PinTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.pink);
  }

  @override
  bool shouldRepaint(_PinTailPainter oldDelegate) => false;
}

/// The flowing candy road that threads through every world stop.
class _TrailPainter extends CustomPainter {
  _TrailPainter(this.points, this.t);
  final List<Offset> points;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    // Smooth path through the stops.
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);

    // Outer white casing.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white.withValues(alpha: 0.6),
    );
    // Inner pink ribbon.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0x55FF7AB0),
    );

    // Flowing dots travelling down the road.
    final dot = Paint()..color = Colors.white;
    for (final metric in path.computeMetrics()) {
      var d = (t * 28) % 28;
      while (d < metric.length) {
        final tan = metric.getTangentForOffset(d);
        if (tan != null) canvas.drawCircle(tan.position, 3, dot);
        d += 28;
      }
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) => old.t != t || old.points != points;
}

/// Circular progress ring drawn around an island stop.
class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 3;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress.clamp(0, 1),
        false,
        Paint()
          ..color = AppColors.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}
