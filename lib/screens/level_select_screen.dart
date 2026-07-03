import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../game/sections.dart';
import '../state/game_state.dart';
import '../widgets/liquid_glass.dart';
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Gradient fallback underneath, hand-made map artwork on top —
          // the illustration keeps its centre column empty for the trail.
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
          ),
          Image.asset(
            'assets/boba/world_map.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          SafeArea(
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

                      // Only the trail painter and the small pulse widgets listen
                      // to the loop — the ~70 island stops and labels are built
                      // once per state change, not once per animation frame.
                      return SingleChildScrollView(
                        controller: _scroll,
                        physics: const BouncingScrollPhysics(),
                        child: SizedBox(
                          width: width,
                          height: mapHeight,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _TrailPainter(points, _loop),
                                ),
                              ),
                              ..._stops(state, points),
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

  // ---------- header ----------
  /// One frosted command strip: back · centred sticker title · star badge.
  Widget _header(GameState state) {
    final total = state.progress.fold<int>(0, (s, v) => s + v);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: LiquidGlass(
        radius: 26,
        blur: 16,
        opacity: 0.55,
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.65),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.8),
                    width: 1.2,
                  ),
                ),
                child: const Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.accent,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Centred sticker-style heading: white outline + candy gradient
            // fill + soft drop shadow, matching the in-game praise words.
            const Expanded(child: Center(child: _StickerTitle('Worlds'))),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFD76B), Color(0xFFFFB020)],
                ),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.white, width: 1.6),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD77A1E).withValues(alpha: 0.45),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, size: 18, color: Colors.white),
                  const SizedBox(width: 4),
                  // Just the collected total — "50/3015" reads as
                  // discouraging; the bar already shows overall progress.
                  Text(
                    '$total',
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

      // Pulsing glow ring behind the current world.
      if (isCurrent) {
        const halo = 150.0;
        widgets.add(
          Positioned(
            left: p.dx - halo / 2,
            top: p.dy - halo / 2,
            child: IgnorePointer(
              child: _PulsingHalo(loop: _loop, color: s.shadow, size: halo),
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
            left: p.dx - 46,
            top: p.dy - _node / 2 - 30,
            width: 92,
            child: IgnorePointer(
              child: Center(child: _BouncingPin(loop: _loop)),
            ),
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
                  color: widget.section.shadow,
                ),
              ),
              // Island body — glossy candy orb when unlocked, frosted glass
              // "mystery" disc when locked.
              Container(
                width: d - 16,
                height: d - 16,
                decoration: widget.unlocked
                    ? BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(-0.35, -0.45),
                          radius: 1.15,
                          colors: [grad.first, grad.last],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.85),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: shadow.withValues(alpha: 0.5),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.5),
                            blurRadius: 6,
                            spreadRadius: -3,
                          ),
                        ],
                      )
                    : BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.5),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.8),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                child: Center(
                  // Locked worlds stay a mystery — hide the themed emoji and
                  // show only a lock until the world is unlocked.
                  child: widget.unlocked
                      ? Text(s.emoji, style: const TextStyle(fontSize: 34))
                      : Icon(
                          Icons.lock_rounded,
                          color: AppColors.muted.withValues(alpha: 0.8),
                          size: 30,
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
    // Glass look without a BackdropFilter — there can be ~70 labels on screen,
    // so a translucent fill + sheen keeps it cheap while still reading as glass.
    return LiquidGlass(
      radius: 16,
      blur: 0,
      opacity: 0.72,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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

/// A bouncy candy "sticker" heading: thick white outline, pink-to-amber
/// gradient fill and a soft drop shadow — the same look as the in-game
/// praise words, so the whole app shares one voice.
class _StickerTitle extends StatelessWidget {
  const _StickerTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 28,
      height: 1,
      fontWeight: FontWeight.w800,
      letterSpacing: 1,
    );
    return Stack(
      children: [
        // Thick white outline.
        Text(
          text,
          maxLines: 1,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 7
              ..strokeJoin = StrokeJoin.round
              ..color = Colors.white,
          ),
        ),
        // Candy gradient fill.
        ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF7AB0), AppColors.accent, Color(0xFFFF9A3D)],
            stops: [0, 0.6, 1],
          ).createShader(rect),
          child: Text(
            text,
            maxLines: 1,
            style: style.copyWith(
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  offset: const Offset(0, 2),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Soft radial glow behind the current world that breathes with the loop.
/// Self-animating so only this widget repaints each frame.
class _PulsingHalo extends StatelessWidget {
  const _PulsingHalo({
    required this.loop,
    required this.color,
    required this.size,
  });

  final Animation<double> loop;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: loop,
      builder: (_, child) {
        final pulse = 0.5 + 0.5 * math.sin(loop.value * 2 * math.pi);
        return Opacity(opacity: 0.35 + 0.35 * pulse, child: child);
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.55), color.withValues(alpha: 0)],
            stops: const [0.25, 1],
          ),
        ),
      ),
    );
  }
}

/// The "PLAY" pin bobbing gently over the current world. Self-animating so
/// only the pin repaints each frame.
class _BouncingPin extends StatelessWidget {
  const _BouncingPin({required this.loop});

  final Animation<double> loop;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: loop,
      builder: (_, child) {
        final pulse = 0.5 + 0.5 * math.sin(loop.value * 2 * math.pi);
        return Transform.translate(offset: Offset(0, -3 * pulse), child: child);
      },
      child: const _PlayPin(),
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
            border: Border.all(color: Colors.white, width: 1.6),
            boxShadow: [
              BoxShadow(
                color: AppColors.pinkShadow.withValues(alpha: 0.55),
                blurRadius: 10,
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
                  letterSpacing: 1,
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

/// The flowing candy road that threads through every world stop. Repaints via
/// the [animation] listenable, so the surrounding widget tree stays static.
class _TrailPainter extends CustomPainter {
  _TrailPainter(this.points, this.animation) : super(repaint: animation);
  final List<Offset> points;
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final t = animation.value;

    // Smooth path through the stops.
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);

    // Soft blurred under-shadow so the road floats over the artwork.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 26
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
        ..color = const Color(0x26C05A8A),
    );
    // Bright white casing.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white.withValues(alpha: 0.85),
    );
    // Inner candy ribbon: a soft rainbow gradient flowing down the trail.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          tileMode: TileMode.mirror,
          colors: [
            Color(0xB3FFB3D2),
            Color(0xB3FFD9A8),
            Color(0xB3B9F0DC),
            Color(0xB3BFD9FF),
            Color(0xB3FFB3D2),
          ],
        ).createShader(path.getBounds()),
    );

    // Flowing glow-dots travelling down the road.
    final glow = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    final core = Paint()..color = Colors.white;
    for (final metric in path.computeMetrics()) {
      var d = (t * 30) % 30;
      while (d < metric.length) {
        final tan = metric.getTangentForOffset(d);
        if (tan != null) {
          canvas.drawCircle(tan.position, 4.4, glow);
          canvas.drawCircle(tan.position, 2.6, core);
        }
        d += 30;
      }
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) => old.points != points;
}

/// Circular progress ring drawn around an island stop.
class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 3;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final sweep = 2 * math.pi * progress.clamp(0, 1);
      // Soft glow under the arc, then the crisp arc itself.
      canvas.drawArc(
        rect,
        -math.pi / 2,
        sweep,
        false,
        Paint()
          ..color = color.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawArc(
        rect,
        -math.pi / 2,
        sweep,
        false,
        Paint()
          ..color = color.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}
