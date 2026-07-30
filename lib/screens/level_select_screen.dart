import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../game/sections.dart';
import '../state/game_state.dart';
import '../widgets/liquid_glass.dart';
import 'world_map_screen.dart';

/// The "Worlds" overview, presented as a candy **staircase**: each world is a
/// glossy island standing on its own landing, and between landings the player
/// climbs a flight of chunky candy steps dotted with footprints. The flights
/// switch back left/right so the whole climb zig-zags down the screen. Tapping
/// a stop opens that world's level map.
class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scroll = ScrollController();
  late final List<GameSection> _sections = buildSections();

  // Continuous loop for the shimmer climbing the steps + current-stop pulse.
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  // Staircase geometry.
  static const double _spacing = 190; // vertical gap between landings
  static const double _topPad = 86;
  static const double _botPad = 110;
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
                      final amp = (width / 2 - _node / 2 - 30).clamp(0.0, 92.0);
                      final centerX = width / 2;
                      // Landings alternate strictly left/right, so every flight
                      // of steps between them is an even diagonal — a switchback
                      // staircase rather than a wobbly road.
                      final points = <Offset>[
                        for (var i = 0; i < n; i++)
                          Offset(
                            centerX + (i.isEven ? -amp : amp),
                            _topPad + i * _spacing,
                          ),
                      ];
                      final mapHeight = _topPad + (n - 1) * _spacing + _botPad;

                      // Only the staircase painter and the small pulse widgets
                      // listen to the loop — the ~70 island stops and labels are
                      // built once per state change, not once per frame.
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
                                  painter: _StairPainter(
                                    points: points,
                                    unlocked: [
                                      for (final s in _sections)
                                        state.isUnlocked(s.start),
                                    ],
                                    tints: [
                                      for (final s in _sections)
                                        s.gradient.last,
                                    ],
                                    animation: _loop,
                                  ),
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
            // FittedBox scales it down gracefully on very narrow screens.
            const Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _StickerTitle("Let's Pop!"),
                ),
              ),
            ),
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

/// The candy staircase that climbs between world stops: a landing under every
/// island and a flight of chunky 3-D steps in between, each stamped with a
/// little footprint once that world has been reached. A soft shine travels down
/// the flight so the climb feels alive. Repaints via the [animation] listenable,
/// so the surrounding widget tree stays static.
class _StairPainter extends CustomPainter {
  _StairPainter({
    required this.points,
    required this.unlocked,
    required this.tints,
    required this.animation,
  }) : super(repaint: animation);

  /// Landing centre of each world stop.
  final List<Offset> points;

  /// Whether each world has been reached — walked steps are candy-coloured,
  /// the rest stay frosted.
  final List<bool> unlocked;

  /// World colour used to tint that stretch of the staircase.
  final List<Color> tints;
  final Animation<double> animation;

  /// Steps in one flight, and where along the flight they sit. The range stops
  /// short of both landings so the treads meet the platforms cleanly.
  static const List<double> _steps = [0.30, 0.44, 0.58, 0.72];
  static const double _treadW = 66;
  static const double _treadH = 18;
  static const double _riser = 10;

  // Locked steps are frosted candy: a white lip fading to lilac, over a
  // deeper lilac riser so the stair edge still reads on a pale background.
  static const Color _frostTop = Color(0xF2FFFFFF);
  static const Color _frostBottom = Color(0xE6E6D9F0);
  static const Color _frostRiser = Color(0xD9C7B3DC);
  static const Color _dropShadow = Color(0x38A8628C);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final t = animation.value;
    final total = (points.length - 1) * _steps.length;

    // Faint guide ribbon so the flights read as one continuous climb.
    final guide = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      guide.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(
      guide,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 30
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
        ..color = Colors.white.withValues(alpha: 0.30),
    );

    // Landings first, then the treads on top — painting strictly top-to-bottom
    // lets each tread hide the riser of the step above it.
    for (var i = 0; i < points.length; i++) {
      _landing(canvas, points[i], tints[i], unlocked[i]);
    }

    var step = 0;
    for (var i = 0; i < points.length - 1; i++) {
      final walked = unlocked[i + 1];
      for (final f in _steps) {
        final c = Offset.lerp(points[i], points[i + 1], f)!;
        final tint = Color.lerp(tints[i], tints[i + 1], f)!;
        // A single highlight sweeping down the whole staircase.
        final phase = (t - step / total) % 1.0;
        final shine = walked && phase < 0.09 ? 1 - phase / 0.09 : 0.0;
        _tread(canvas, c, tint, walked, shine, step.isEven);
        step++;
      }
    }
  }

  /// Wide platform the world island stands on — the landing at the top of each
  /// flight. Tinted lighter than the steps so the island still leads the eye.
  void _landing(Canvas canvas, Offset c, Color tint, bool walked) {
    final pastel = Color.lerp(tint, Colors.white, 0.45)!;
    final top = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c.translate(0, 40), width: 106, height: 26),
      const Radius.circular(14),
    );
    final riser = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c.translate(0, 47), width: 98, height: 26),
      const Radius.circular(14),
    );
    canvas.drawRRect(
      top.shift(const Offset(0, 14)),
      Paint()
        ..color = _dropShadow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawRRect(
      riser,
      Paint()
        ..color = walked
            ? Color.lerp(pastel, Colors.black, 0.22)!.withValues(alpha: 0.85)
            : _frostRiser,
    );
    canvas.drawRRect(
      top,
      Paint()..shader = _topShader(top.outerRect, pastel, walked),
    );
    canvas.drawRRect(
      top,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = Colors.white.withValues(alpha: walked ? 0.95 : 0.75),
    );
  }

  /// One candy step: soft cast shadow, darker riser, glossy top face, white
  /// rim, travelling shine, and a footprint once it has been walked.
  void _tread(
    Canvas canvas,
    Offset c,
    Color tint,
    bool walked,
    double shine,
    bool leftFoot,
  ) {
    final top = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c, width: _treadW, height: _treadH),
      const Radius.circular(9),
    );
    final riser = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: c.translate(0, _riser * 0.6),
        width: _treadW - 6,
        height: _treadH,
      ),
      const Radius.circular(9),
    );

    canvas.drawRRect(
      top.shift(const Offset(0, 9)),
      Paint()
        ..color = _dropShadow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawRRect(
      riser,
      Paint()
        ..color = walked
            ? Color.lerp(tint, Colors.black, 0.26)!.withValues(alpha: 0.9)
            : _frostRiser,
    );
    canvas.drawRRect(
      top,
      Paint()..shader = _topShader(top.outerRect, tint, walked),
    );
    canvas.drawRRect(
      top,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = Colors.white.withValues(alpha: walked ? 0.95 : 0.7),
    );
    if (shine > 0) {
      canvas.drawRRect(
        top,
        Paint()..color = Colors.white.withValues(alpha: 0.45 * shine),
      );
    }
    // Every step carries a footprint so the climb reads as a walk — bright and
    // white on the candy steps already walked, a faint press on the rest.
    _foot(
      canvas,
      c.translate(leftFoot ? -14 : 14, -1),
      leftFoot,
      walked
          ? Colors.white.withValues(alpha: 0.72)
          : AppColors.muted.withValues(alpha: 0.3),
    );
  }

  /// Glossy top face: a lighter lip fading into the world colour (or frosted
  /// lilac while the world is still locked).
  Shader _topShader(Rect rect, Color tint, bool walked) {
    final colors = walked
        ? [
            Color.lerp(tint, Colors.white, 0.65)!,
            Color.lerp(tint, Colors.white, 0.18)!,
          ]
        : [_frostTop, _frostBottom];
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
    ).createShader(rect);
  }

  /// A small footprint pressed into a step.
  void _foot(Canvas canvas, Offset c, bool left, Color color) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(left ? -0.3 : 0.3);
    final paint = Paint()..color = color;
    // Sole, then a little arc of toes above it.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 2.4), width: 8, height: 10),
      paint,
    );
    // Mirror the toe row so the big toe sits on the inner edge of each foot.
    final dir = left ? 1.0 : -1.0;
    for (var i = 0; i < 4; i++) {
      canvas.drawCircle(
        Offset(dir * (-3.2 + i * 2.1), -5.2 - (i == 0 ? 0 : 0.6)),
        i == 0 ? 1.3 : 1.05,
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StairPainter old) =>
      !listEquals(old.points, points) ||
      !listEquals(old.unlocked, unlocked) ||
      !listEquals(old.tints, tints);
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
