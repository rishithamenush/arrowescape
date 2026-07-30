import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/theme.dart';
import '../game/sections.dart';
import '../state/game_state.dart';
import '../widgets/liquid_glass.dart';
import 'world_map_screen.dart';

/// The "Worlds" overview, presented as an **isometric candy staircase**: every
/// step is a soft-cornered 3-D block, and consecutive blocks lock together into
/// flights that switch back down the screen. Each world stands on a wider plinth
/// where two flights meet, and the flights vary in length so the climb keeps
/// changing as it scrolls. Tapping a stop opens that world's level map.
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

  // Isometric grid. A step is one cube: a `_tileW` x `_tileH` diamond top face
  // over a `_cubeD` deep body. Walking one tile along an iso axis moves half a
  // tile across and half a tile down the screen; dropping one step down adds
  // the cube depth — so consecutive cubes lock together into a staircase.
  static const double _tileW = 60;
  static const double _tileH = 30;
  static const double _cubeD = 16;
  static const double _stepDX = _tileW / 2;
  static const double _stepDY = _tileH / 2 + _cubeD;

  /// Steps per flight, cycled down the climb so the switchbacks keep changing
  /// length instead of repeating one shape.
  static const List<int> _flightLens = [4, 3, 5, 4, 6, 3, 5, 4, 6];

  /// Breathing room between the bottom of a flight and the next landing.
  static const double _landingGap = 38;

  static const double _topPad = 78;
  static const double _botPad = 110;
  static const double _node = 72; // island diameter

  // Layout is rebuilt only when the width changes; the climb is long, so
  // recomputing it every frame would be wasteful.
  double _laidOutFor = -1;
  List<Offset> _landings = const [];
  List<_IsoStep> _steps = const [];
  double _mapHeight = 0;

  /// Whether the player has scrolled away from their own world — drives the
  /// floating "Continue" button, so it only appears when it is useful.
  final ValueNotifier<bool> _strayed = ValueNotifier(false);

  /// Index of the world the player is on.
  int _currentWorld(GameState state) =>
      (state.unlocked ~/ kSectionSize).clamp(0, _sections.length - 1);

  /// Walks the whole climb once: a landing for every world, and between them a
  /// flight of cubes stepping down one iso tile at a time. Flights head back
  /// towards the middle of the screen and are shortened if they would run off
  /// the edge, so the staircase switchbacks stay in frame at any width.
  void _buildLayout(double width) {
    if (width == _laidOutFor) return;
    _laidOutFor = width;

    final minX = 40 + _tileW / 2;
    final maxX = width - 40 - _tileW / 2;
    final landings = <Offset>[];
    final steps = <_IsoStep>[];
    var p = Offset(width * 0.34, _topPad);
    var index = 0;

    for (var i = 0; i < _sections.length; i++) {
      landings.add(p);
      if (i == _sections.length - 1) break;

      final dir = p.dx > width / 2 ? -1.0 : 1.0;
      var k = _flightLens[i % _flightLens.length];
      while (k > 2) {
        final end = p.dx + dir * _stepDX * k;
        if (end >= minX && end <= maxX) break;
        k--;
      }
      for (var s = 1; s <= k; s++) {
        steps.add(
          _IsoStep(
            p + Offset(dir * _stepDX * s, _stepDY * s),
            i + 1,
            index++,
            dir > 0,
          ),
        );
      }
      p += Offset(dir * _stepDX * k, _stepDY * k + _landingGap);
    }

    _landings = landings;
    _steps = steps;
    _mapHeight = landings.last.dy + _botPad;
  }

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_watchScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients || _landings.isEmpty) return;
      final state = GameScope.read(context);
      final current = _currentWorld(state);
      final target =
          _landings[current].dy - _scroll.position.viewportDimension / 2;
      _scroll.jumpTo(target.clamp(0, _scroll.position.maxScrollExtent));
    });
  }

  /// Flags when the player's own world has scrolled out of view.
  void _watchScroll() {
    if (!mounted || !_scroll.hasClients || _landings.isEmpty) return;
    final current = _currentWorld(GameScope.read(context));
    final viewport = _scroll.position.viewportDimension;
    final middle = _scroll.offset + viewport / 2;
    final away = (_landings[current].dy - middle).abs() > viewport * 0.55;
    if (away != _strayed.value) _strayed.value = away;
  }

  @override
  void dispose() {
    _scroll.removeListener(_watchScroll);
    _strayed.dispose();
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
                      _buildLayout(width);

                      // Only the staircase painter and the small pulse widgets
                      // listen to the loop — the ~70 island stops and labels are
                      // built once per state change, not once per frame.
                      return SingleChildScrollView(
                        controller: _scroll,
                        physics: const BouncingScrollPhysics(),
                        child: SizedBox(
                          width: width,
                          height: _mapHeight,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _IsoStairPainter(
                                    landings: _landings,
                                    steps: _steps,
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
                              ..._stops(state, _landings),
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
          // Floating jump-back-to-your-world button, shown only once the
          // player has scrolled away from it.
          Positioned(
            left: 0,
            right: 0,
            bottom: 22,
            child: Center(
              child: ValueListenableBuilder<bool>(
                valueListenable: _strayed,
                builder: (_, away, child) => IgnorePointer(
                  ignoring: !away,
                  // `target` drives the effects both ways, so the button slides
                  // back down when the player scrolls home again.
                  child: child!
                      .animate(target: away ? 1 : 0)
                      .fadeIn(duration: 220.ms)
                      .slideY(
                        begin: 0.7,
                        end: 0,
                        duration: 280.ms,
                        curve: Curves.easeOutBack,
                      ),
                ),
                child: _continueButton(state),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- header ----------
  /// One frosted command strip: back · sticker title · star badge, over a slim
  /// bar showing how far through the whole climb the player is.
  Widget _header(GameState state) {
    final total = state.progress.fold<int>(0, (s, v) => s + v);
    final worlds = _sections.length;
    final reached = (state.unlocked ~/ kSectionSize + 1).clamp(1, worlds);

    return Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: LiquidGlass(
            radius: 26,
            blur: 16,
            opacity: 0.55,
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _GlassIconButton(
                      icon: Icons.chevron_left_rounded,
                      onTap: () => Navigator.of(context).pop(),
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
                    _CandyChip(
                      icon: Icons.star_rounded,
                      // Just the collected total — "50/3015" reads as
                      // discouraging; the bar already shows overall progress.
                      label: '$total',
                      colors: const [AppColors.amberLight, AppColors.amber],
                      shadow: AppColors.amberShadow,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _ProgressBar(
                        value: reached / worlds,
                        colors: const [AppColors.pinkLight, AppColors.pink],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'WORLD $reached / $worlds',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.body,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 350.ms)
        .slideY(
          begin: -0.4,
          end: 0,
          duration: 420.ms,
          curve: Curves.easeOutCubic,
        );
  }

  /// Jumps the map back to the world the player is on. On a climb this long
  /// it is easy to scroll away and lose the thread.
  Widget _continueButton(GameState state) {
    final i = _currentWorld(state);
    final s = _sections[i];
    return GestureDetector(
      onTap: () {
        if (!_scroll.hasClients || i >= _landings.length) return;
        final target = _landings[i].dy - _scroll.position.viewportDimension / 2;
        _scroll.animateTo(
          target.clamp(0.0, _scroll.position.maxScrollExtent),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 18, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [s.gradient.first, s.gradient.last],
          ),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: s.shadow.withValues(alpha: 0.5),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.my_location_rounded,
              size: 18,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              'Continue · ${s.name}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
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
        const halo = 118.0;
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
            top: p.dy - _node / 2 - 28,
            width: 92,
            child: IgnorePointer(child: const Center(child: _BouncingPin())),
          ),
        );
      }

      // World card on the OPEN side of the island (right of left-side stops,
      // left of right-side stops) so it never crowds the stairs or the next
      // node. Vertically centred on the island.
      const cardW = 152.0;
      final onLeft = p.dx < centerX - 1;
      final cardLeft = onLeft
          ? p.dx + _node / 2 - 2
          : p.dx - _node / 2 + 2 - cardW;
      widgets.add(
        Positioned(
          left: cardLeft,
          top: p.dy - 30,
          width: cardW,
          child: Align(
            alignment: onLeft ? Alignment.centerLeft : Alignment.centerRight,
            child:
                _WorldCard(
                      section: s,
                      unlocked: unlocked,
                      current: isCurrent,
                      completed: completed,
                      stars: stars,
                      maxStars: maxStars,
                      onTap: unlocked
                          ? () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => WorldMapScreen(section: s),
                              ),
                            )
                          : null,
                    )
                    // Cards drift in from behind their island. Staggering on a
                    // short cycle keeps nearby cards cascading without giving
                    // the far end of the climb a several-second delay.
                    .animate()
                    .fadeIn(duration: 320.ms, delay: (i % 6 * 55).ms)
                    .slideX(
                      begin: onLeft ? -0.18 : 0.18,
                      end: 0,
                      duration: 380.ms,
                      delay: (i % 6 * 55).ms,
                      curve: Curves.easeOutCubic,
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
                width: d - 14,
                height: d - 14,
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
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: shadow.withValues(alpha: 0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
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
                      ? Text(s.emoji, style: const TextStyle(fontSize: 26))
                      : Icon(
                          Icons.lock_rounded,
                          color: AppColors.muted.withValues(alpha: 0.8),
                          size: 24,
                        ),
                ),
              ),
              // Glossy top highlight.
              Positioned(
                top: 10,
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
                  bottom: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 0.5,
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
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: shadow,
                      ),
                    ),
                  ),
                ),
              // Crown for a fully-perfected world.
              if (widget.perfected)
                Positioned(
                  top: -12,
                  child: Text('👑', style: TextStyle(fontSize: 18)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The card beside each island: world name, how far through it the player is,
/// and the stars collected. Locked worlds keep their name and theme hidden and
/// show what it takes to open them instead.
class _WorldCard extends StatefulWidget {
  const _WorldCard({
    required this.section,
    required this.unlocked,
    required this.current,
    required this.completed,
    required this.stars,
    required this.maxStars,
    required this.onTap,
  });

  final GameSection section;
  final bool unlocked;
  final bool current;
  final int completed;
  final int stars;
  final int maxStars;
  final VoidCallback? onTap;

  @override
  State<_WorldCard> createState() => _WorldCardState();
}

class _WorldCardState extends State<_WorldCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.section;
    final done = widget.completed;

    // Glass look without a BackdropFilter — there can be ~70 cards in the
    // tree, so a translucent fill + sheen keeps it cheap while still reading
    // as glass.
    Widget card = LiquidGlass(
      radius: 16,
      blur: 0,
      opacity: widget.unlocked ? 0.82 : 0.62,
      padding: const EdgeInsets.fromLTRB(11, 7, 11, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (!widget.unlocked) ...[
                Icon(
                  Icons.lock_rounded,
                  size: 13,
                  color: AppColors.muted.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  widget.unlocked ? s.name : 'Locked',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    color: widget.unlocked ? s.shadow : AppColors.muted,
                  ),
                ),
              ),
              if (widget.current)
                Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'NOW',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: Colors.white,
                        ),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(
                      end: 1.09,
                      duration: 780.ms,
                      curve: Curves.easeInOut,
                    ),
            ],
          ),
          const SizedBox(height: 5),
          if (widget.unlocked) ...[
            _ProgressBar(
              value: s.count == 0 ? 0 : done / s.count,
              colors: s.gradient,
              height: 5,
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 13,
                  color: AppColors.amber,
                ),
                const SizedBox(width: 3),
                Text(
                  '${widget.stars}/${widget.maxStars}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.body,
                  ),
                ),
                const Spacer(),
                Text(
                  '$done/${s.count}',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ] else
            Text(
              'Opens at level ${s.start + 1}',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
        ],
      ),
    );

    // A slow light sweep marks the world the player is on.
    if (widget.current) {
      card = card
          .animate(onPlay: (c) => c.repeat(period: 2800.ms))
          .shimmer(
            delay: 700.ms,
            duration: 1300.ms,
            color: Colors.white.withValues(alpha: 0.6),
          );
    }

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
        scale: _down ? 0.94 : 1,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: card,
      ),
    );
  }
}

/// A slim rounded progress bar with a candy gradient fill.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.value,
    required this.colors,
    this.height = 6,
  });

  final double value;
  final List<Color> colors;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Stack(
        children: [
          Container(height: height, color: Colors.white.withValues(alpha: 0.6)),
          FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The round frosted button used for the back arrow.
class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
        child: Icon(icon, color: AppColors.accent, size: 28),
      ),
    );
  }
}

/// A glossy candy pill for a small counter, like the star total.
class _CandyChip extends StatelessWidget {
  const _CandyChip({
    required this.icon,
    required this.label,
    required this.colors,
    required this.shadow,
  });

  final IconData icon;
  final String label;
  final List<Color> colors;
  final Color shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white, width: 1.6),
        boxShadow: [
          BoxShadow(
            color: shadow.withValues(alpha: 0.45),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
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

/// The "PLAY" pin over the current world: bobbing, with a light sweep across
/// it. Only ever one on screen, so it can own its animation.
class _BouncingPin extends StatelessWidget {
  const _BouncingPin();

  @override
  Widget build(BuildContext context) {
    return const _PlayPin()
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -5, duration: 900.ms, curve: Curves.easeInOut)
        .animate(onPlay: (c) => c.repeat(period: 2600.ms))
        .shimmer(
          delay: 600.ms,
          duration: 1100.ms,
          color: Colors.white.withValues(alpha: 0.75),
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

/// One block of the climb: where it sits and which world's flight it belongs to.
class _IsoStep {
  const _IsoStep(this.center, this.world, this.index, this.headingRight);

  /// Centre of the block's top face.
  final Offset center;

  /// The world this flight climbs down to — decides colour and locked state.
  final int world;

  /// Position in the whole climb, used for the travelling shine and to keep
  /// each block's markings stable between frames.
  final int index;

  /// Which way this flight is heading, so footprints point down the stairs.
  final bool headingRight;
}

/// The isometric candy staircase. Every step is a soft-cornered 3-D block, and
/// consecutive blocks lock together into a flight — one iso tile across and one
/// step down each time. Worlds stand on wider plinths where the flights switch
/// back. Blocks of worlds already reached are vivid candy; the rest are frosted
/// glass. Repaints via the [animation] listenable, so the surrounding widget
/// tree stays static.
class _IsoStairPainter extends CustomPainter {
  _IsoStairPainter({
    required this.landings,
    required this.steps,
    required this.unlocked,
    required this.tints,
    required this.animation,
  }) : super(repaint: animation);

  /// Centre of each world's plinth.
  final List<Offset> landings;

  /// Every block of the climb, ordered top to bottom.
  final List<_IsoStep> steps;

  /// Whether each world has been reached.
  final List<bool> unlocked;

  /// World colour used to tint that stretch of the climb.
  final List<Color> tints;
  final Animation<double> animation;

  static const double _tileW = 62;
  static const double _tileH = 31;
  static const double _cubeD = 17;

  // Plinths are the same block, a little over a tile across — big enough to
  // read as a landing, small enough that the island still sits on top of it.
  static const double _plinthW = 78;
  static const double _plinthH = 39;
  static const double _plinthD = 19;
  static const double _plinthDrop = 26;

  /// How far the corners of a block are rounded, as a fraction of each edge.
  /// This is what keeps the blocks soft instead of sharp-edged.
  static const double _round = 0.26;

  /// Slices per logical pixel of depth when extruding a block. Sub-pixel
  /// slices are what keep the side a smooth curved surface instead of a
  /// visibly banded stack. Affordable because the painter culls to the
  /// viewport, so only a dozen or so blocks are ever drawn.
  static const double _slicesPerPx = 2.2;

  // A world still out of reach is frosted glass: near-white with the faintest
  // cool tint, so it sits quietly on the artwork and lets the candy blocks of
  // reached worlds carry the colour.
  static const Color _iceTop = Color(0xFFFFFFFF);
  static const Color _iceTopEdge = Color(0xFFEDEDF6);
  static const Color _iceSide = Color(0xFFE4E1F0);
  static const Color _iceSideDeep = Color(0xFFC5C0DA);

  @override
  void paint(Canvas canvas, Size size) {
    if (steps.isEmpty || landings.isEmpty) return;
    final t = animation.value;
    // The climb is far taller than the viewport; only paint what is on screen.
    final clip = canvas.getLocalClipBounds().inflate(80);

    // The first world's plinth has no flight above it, so draw it first; every
    // other plinth is drawn with the flight that arrives at it, keeping the
    // whole climb in strict top-to-bottom order for correct overlap.
    if (_visible(landings.first, clip)) _plinth(canvas, landings.first, 0);

    var next = 1;
    for (final s in steps) {
      // Any plinth that sits above this block belongs earlier in the stack.
      while (next < landings.length && landings[next].dy < s.center.dy) {
        if (_visible(landings[next], clip)) {
          _plinth(canvas, landings[next], next);
        }
        next++;
      }
      if (!_visible(s.center, clip)) continue;
      final lit = s.world < unlocked.length && unlocked[s.world];
      // A single highlight sweeping down the whole climb.
      final phase = (t - s.index / steps.length) % 1.0;
      final shine = lit && phase < 0.07 ? 1 - phase / 0.07 : 0.0;
      _block(
        canvas,
        s.center,
        _tileW,
        _tileH,
        _cubeD,
        tints[math.min(s.world, tints.length - 1)],
        lit,
        step: s,
        shine: shine,
      );
    }
    for (; next < landings.length; next++) {
      if (_visible(landings[next], clip)) _plinth(canvas, landings[next], next);
    }
  }

  bool _visible(Offset c, Rect clip) => c.dy >= clip.top && c.dy <= clip.bottom;

  /// The wider block a world island stands on.
  void _plinth(Canvas canvas, Offset c, int world) {
    _block(
      canvas,
      c.translate(0, _plinthDrop),
      _plinthW,
      _plinthH,
      _plinthD,
      Color.lerp(tints[math.min(world, tints.length - 1)], Colors.white, 0.3)!,
      world < unlocked.length && unlocked[world],
    );
  }

  /// One soft isometric block: a rounded diamond top face over a body extruded
  /// in shaded slices, finished with a bright rim and a highlight.
  void _block(
    Canvas canvas,
    Offset c,
    double w,
    double h,
    double d,
    Color tint,
    bool lit, {
    _IsoStep? step,
    double shine = 0,
  }) {
    final face = _diamond(w / 2, h / 2).shift(c);

    // Contact shadow: soft, wide, and low — modern depth without a hard edge.
    canvas.save();
    canvas.translate(c.dx, c.dy + d + h * 0.34);
    canvas.scale(1, 0.42);
    canvas.drawCircle(
      Offset.zero,
      w * 0.46,
      Paint()
        ..color = const Color(0x2E7A4E68)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    canvas.restore();

    // Body: the same face stamped down the depth, darkening as it goes, so the
    // side reads as one smoothly curved surface.
    final sideTop = lit ? Color.lerp(tint, Colors.white, 0.1)! : _iceSide;
    final sideEnd = lit ? Color.lerp(tint, Colors.black, 0.3)! : _iceSideDeep;
    final slices = (d * _slicesPerPx).ceil();
    for (var i = slices; i >= 1; i--) {
      final k = i / slices;
      canvas.drawPath(
        face.shift(Offset(0, d * k)),
        // Ease the shading so the curve is strongest near the bottom edge.
        Paint()..color = Color.lerp(sideTop, sideEnd, k * k)!,
      );
    }

    // Top face.
    canvas.drawPath(
      face,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: lit
              ? [
                  Color.lerp(tint, Colors.white, 0.72)!,
                  Color.lerp(tint, Colors.white, 0.34)!,
                ]
              : const [_iceTop, _iceTopEdge],
        ).createShader(Rect.fromCenter(center: c, width: w, height: h)),
    );

    // A single soft footprint, kept faint — texture, not decoration.
    if (step != null) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.scale(1, _tileH / _tileW);
      _foot(
        canvas,
        step,
        lit
            ? Colors.white.withValues(alpha: 0.55)
            : const Color(0xFF9A86AB).withValues(alpha: 0.22),
      );
      canvas.restore();
    }

    // Bright rim around the top face, and a highlight across its upper half.
    canvas.drawPath(
      face,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = Colors.white.withValues(alpha: lit ? 0.85 : 0.95),
    );
    canvas.save();
    canvas.clipPath(face);
    canvas.drawPath(
      _diamond(w * 0.36, h * 0.36).shift(c.translate(-w * 0.12, -h * 0.14)),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.34)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.restore();

    if (shine > 0) {
      canvas.drawPath(
        face,
        Paint()..color = Colors.white.withValues(alpha: 0.4 * shine),
      );
    }
  }

  /// A diamond with softly rounded corners, centred on the origin.
  Path _diamond(double hw, double hh) {
    final n = Offset(0, -hh);
    final e = Offset(hw, 0);
    final s = Offset(0, hh);
    final w = Offset(-hw, 0);
    Offset cut(Offset a, Offset b) => Offset.lerp(a, b, _round)!;

    final start = cut(n, e);
    final path = Path()..moveTo(start.dx, start.dy);
    for (final (from, corner, to) in [
      (n, e, s),
      (e, s, w),
      (s, w, n),
      (w, n, e),
    ]) {
      final a = cut(corner, from);
      final b = cut(corner, to);
      path
        ..lineTo(a.dx, a.dy)
        ..quadraticBezierTo(corner.dx, corner.dy, b.dx, b.dy);
    }
    return path..close();
  }

  /// A footprint pressed into a step. Drawn oversized because the caller has
  /// squashed the canvas onto the iso top face, and turned to point the way the
  /// flight is heading.
  void _foot(Canvas canvas, _IsoStep step, Color color) {
    final left = step.index.isEven;
    canvas.save();
    canvas.translate(left ? -7 : 7, left ? 4 : -4);
    canvas.rotate((step.headingRight ? 0.9 : -0.9) + (left ? -0.18 : 0.18));
    final paint = Paint()..color = color;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 3.5), width: 10, height: 17),
      paint,
    );
    // Mirror the toe row so the big toe sits on the inner edge of each foot.
    final dir = left ? 1.0 : -1.0;
    for (var i = 0; i < 4; i++) {
      canvas.drawCircle(
        Offset(dir * (-4 + i * 2.6), -8.4 - (i == 0 ? 0 : 0.8)),
        i == 0 ? 1.7 : 1.35,
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IsoStairPainter old) =>
      !identical(old.steps, steps) ||
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
        ..strokeWidth = 4.5,
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
          ..strokeWidth = 6.5
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
