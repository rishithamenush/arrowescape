import 'dart:ui' show ImageFilter;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../core/theme.dart';
import '../game/sections.dart';
import '../state/game_state.dart';
import 'world_map_screen.dart';

/// The "Worlds" screen: a scrolling **candy journey**. A glowing ribbon threads
/// down the screen through one stop per world; each stop is a soft clay orb
/// wrapped in a progress ring, paired with a frosted-glass card carrying the
/// world's name, level progress and stars. The ribbon is lit up to the world
/// the player has reached and frosted beyond it, so progress is readable at a
/// glance while scrolling.
///
/// Built on slivers, so only the handful of rows on screen exist at a time —
/// which is what makes the real backdrop blur on every card affordable.
class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  final ScrollController _scroll = ScrollController();
  late final List<GameSection> _sections = buildSections();
  late final ConfettiController _confetti = ConfettiController(
    duration: const Duration(milliseconds: 700),
  );

  /// Whether the player has scrolled away from their own world — drives the
  /// floating "Continue" button, so it only appears when it is useful.
  final ValueNotifier<bool> _strayed = ValueNotifier(false);

  static const double _rowH = 178;

  /// The world the player is on carries a play button, so its row is taller.
  static const double _heroH = 240;
  static const double _barExpanded = 138;
  static const double _barCollapsed = 66;
  static const double _listTopPad = 6;

  int get _current => _currentWorldOf(GameScope.read(context));

  int _currentWorldOf(GameState state) =>
      (state.unlocked ~/ kSectionSize).clamp(0, _sections.length - 1);

  double _rowHeight(int i, int current) => i == current ? _heroH : _rowH;

  /// Scroll offset that centres world [i] in the viewport.
  double _offsetFor(int i) {
    final current = _current;
    final viewport = _scroll.position.viewportDimension;
    // Every row above `i` is a standard row except the hero, which is taller.
    final above = i * _rowH + (i > current ? _heroH - _rowH : 0);
    return _barExpanded +
        _listTopPad +
        above +
        _rowHeight(i, current) / 2 -
        (viewport + _barCollapsed) / 2;
  }

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_watchScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.jumpTo(
        _offsetFor(_current).clamp(0.0, _scroll.position.maxScrollExtent),
      );
      _confetti.play();
    });
  }

  /// Flags when the player's own world has scrolled out of view.
  void _watchScroll() {
    if (!mounted || !_scroll.hasClients) return;
    final away =
        (_scroll.offset - _offsetFor(_current)).abs() >
        _scroll.position.viewportDimension * 0.55;
    if (away != _strayed.value) _strayed.value = away;
  }

  @override
  void dispose() {
    _scroll.removeListener(_watchScroll);
    _strayed.dispose();
    _confetti.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = GameScope.of(context);
    final current = _currentWorldOf(state);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _Backdrop(scroll: _scroll),
          AnimationLimiter(
            child: CustomScrollView(
              controller: _scroll,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: _barExpanded,
                  toolbarHeight: _barCollapsed,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  flexibleSpace: LayoutBuilder(
                    builder: (context, box) {
                      final top = MediaQuery.paddingOf(context).top;
                      final range = _barExpanded - _barCollapsed;
                      final t = ((box.maxHeight - top - _barCollapsed) / range)
                          .clamp(0.0, 1.0);
                      return _Header(
                        state: state,
                        worlds: _sections.length,
                        current: current,
                        expansion: t,
                      );
                    },
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.only(top: _listTopPad),
                  sliver: SliverList.builder(
                    itemCount: _sections.length,
                    itemBuilder: (context, i) =>
                        AnimationConfiguration.staggeredList(
                          // Stagger on a short cycle: `position: i` would give
                          // rows deep in the list multi-second delays, so they
                          // would sit blank while the player scrolls to them.
                          position: i % 6,
                          duration: const Duration(milliseconds: 420),
                          child: SlideAnimation(
                            verticalOffset: 40,
                            child: FadeInAnimation(
                              child: _WorldRow(
                                sections: _sections,
                                index: i,
                                state: state,
                                height: _rowHeight(i, current),
                                confetti: i == current ? _confetti : null,
                                onOpen: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        WorldMapScreen(section: _sections[i]),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
          ),
          // Floating jump-back-to-your-world button, shown only once the
          // player has scrolled away from it.
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: Center(
              child: ValueListenableBuilder<bool>(
                valueListenable: _strayed,
                builder: (_, away, child) => IgnorePointer(
                  ignoring: !away,
                  // `target` drives the effects both ways, so the button slides
                  // back down when the player scrolls home again.
                  child: child!
                      .animate(target: away ? 1 : 0)
                      .fadeIn(duration: 200.ms)
                      .slideY(
                        begin: 0.8,
                        end: 0,
                        duration: 300.ms,
                        curve: Curves.easeOutBack,
                      ),
                ),
                child: _ContinuePill(
                  section: _sections[current],
                  onTap: () {
                    if (!_scroll.hasClients) return;
                    _scroll.animateTo(
                      _offsetFor(
                        current,
                      ).clamp(0.0, _scroll.position.maxScrollExtent),
                      duration: const Duration(milliseconds: 520),
                      curve: Curves.easeOutCubic,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- backdrop

/// The layered background: the painted candy world, a few drifting blurred
/// blobs, and a scrim under the header. Each layer moves at its own rate as
/// the map scrolls, which gives the screen depth without any extra assets.
class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.scroll});

  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        ),
        _Parallax(
          scroll: scroll,
          rate: 0.10,
          child: Image.asset(
            'assets/boba/world_map.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
        // Soft colour blobs drifting faster than the artwork.
        _Parallax(
          scroll: scroll,
          rate: 0.26,
          child: IgnorePointer(
            child: Stack(
              children: [
                _blob(
                  size.width * 0.06,
                  size.height * 0.18,
                  190,
                  AppColors.pinkLight,
                ),
                _blob(
                  size.width * 0.62,
                  size.height * 0.42,
                  230,
                  AppColors.mintLight,
                ),
                _blob(
                  size.width * 0.20,
                  size.height * 0.74,
                  210,
                  AppColors.amberLight,
                ),
              ],
            ),
          ),
        ),
        // Keeps the frosted header readable over busy artwork.
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            height: 190,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.42),
                  Colors.white.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _blob(double left, double top, double size, Color color) => Positioned(
    left: left,
    top: top,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.32), color.withValues(alpha: 0)],
        ),
      ),
    ),
  );
}

/// Translates its child against the scroll position.
class _Parallax extends StatelessWidget {
  const _Parallax({
    required this.scroll,
    required this.rate,
    required this.child,
  });

  final ScrollController scroll;
  final double rate;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scroll,
      builder: (_, inner) => Transform.translate(
        offset: Offset(0, scroll.hasClients ? -scroll.offset * rate : 0),
        child: inner,
      ),
      child: child,
    );
  }
}

// ------------------------------------------------------------------ header

/// The collapsing top bar. Expanded it shows the overall progress bar; as it
/// shrinks that row fades out and only the title strip is left.
class _Header extends StatelessWidget {
  const _Header({
    required this.state,
    required this.worlds,
    required this.current,
    required this.expansion,
  });

  final GameState state;
  final int worlds;
  final int current;

  /// 1 when fully expanded, 0 when collapsed to the pinned strip.
  final double expansion;

  @override
  Widget build(BuildContext context) {
    final stars = state.progress.fold<int>(0, (s, v) => s + v);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.44),
                borderRadius: BorderRadius.circular(26),
                border: GradientBoxBorder(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.9),
                      Colors.white.withValues(alpha: 0.25),
                    ],
                  ),
                  width: 1.4,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _GlassIconButton(
                        icon: Icons.chevron_left_rounded,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const Expanded(
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: _StickerTitle("Let's Pop!"),
                          ),
                        ),
                      ),
                      _CandyChip(
                        icon: Icons.star_rounded,
                        label: '$stars',
                        colors: const [AppColors.amberLight, AppColors.amber],
                        shadow: AppColors.amberShadow,
                      ),
                    ],
                  ),
                  // Collapses away with the bar instead of overflowing.
                  ClipRect(
                    child: Align(
                      heightFactor: expansion,
                      child: Opacity(
                        opacity: expansion,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: LinearPercentIndicator(
                            percent: ((current + 1) / worlds).clamp(0.0, 1.0),
                            lineHeight: 9,
                            barRadius: const Radius.circular(9),
                            padding: EdgeInsets.zero,
                            animation: true,
                            animationDuration: 900,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.55,
                            ),
                            linearGradient: const LinearGradient(
                              colors: [AppColors.pinkLight, AppColors.pink],
                            ),
                            trailing: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                '${current + 1}/$worlds',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.body,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------- rows

/// One world on the journey: the ribbon passing through, the clay stop, and
/// the glass card beside it. Stops alternate sides down the screen.
class _WorldRow extends StatelessWidget {
  const _WorldRow({
    required this.sections,
    required this.index,
    required this.state,
    required this.height,
    required this.confetti,
    required this.onOpen,
  });

  final List<GameSection> sections;
  final int index;
  final GameState state;
  final double height;
  final ConfettiController? confetti;
  final VoidCallback onOpen;

  static const double _node = 92;

  /// Horizontal position of a stop, as a fraction of the width.
  static double _laneOf(int i) => i.isEven ? 0.26 : 0.74;

  @override
  Widget build(BuildContext context) {
    final s = sections[index];
    final unlocked = state.isUnlocked(s.start);
    final current = state.unlocked >= s.start && state.unlocked <= s.end;

    var done = 0, stars = 0;
    for (var l = s.start; l <= s.end; l++) {
      if (state.starsFor(l) > 0) done++;
      stars += state.starsFor(l);
    }

    // The ribbon is lit as far as the player has reached.
    final litIn = unlocked;
    final litOut =
        index + 1 < sections.length &&
        state.isUnlocked(sections[index + 1].start);

    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final x = w * _laneOf(index);
        final prevX = index == 0 ? x : w * _laneOf(index - 1);
        final nextX = index == sections.length - 1 ? x : w * _laneOf(index + 1);
        final onLeft = _laneOf(index) < 0.5;

        return SizedBox(
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _RibbonPainter(
                    prevX: prevX,
                    x: x,
                    nextX: nextX,
                    litIn: litIn,
                    litOut: litOut,
                    color: s.gradient.last,
                    nextColor: index + 1 < sections.length
                        ? sections[index + 1].gradient.last
                        : s.gradient.last,
                    first: index == 0,
                    last: index == sections.length - 1,
                  ),
                ),
              ),
              // The card fills the side of the row the stop is not on.
              Positioned(
                left: onLeft ? x + _node / 2 - 6 : 14,
                right: onLeft ? 14 : w - (x - _node / 2 + 6),
                top: 0,
                bottom: 0,
                child: Center(
                  child: _WorldCard(
                    section: s,
                    unlocked: unlocked,
                    current: current,
                    done: done,
                    stars: stars,
                    onTap: unlocked ? onOpen : null,
                  ),
                ),
              ),
              Positioned(
                left: x - _node / 2,
                top: (height - _node) / 2,
                child: _WorldStop(
                  section: s,
                  unlocked: unlocked,
                  current: current,
                  progress: s.count == 0 ? 0 : done / s.count,
                  perfected: done == s.count && stars == s.count * 3,
                  diameter: _node,
                  confetti: confetti,
                  onTap: unlocked ? onOpen : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The glowing ribbon threaded through the stops. Vertical tangents at the row
/// edges mean neighbouring rows join seamlessly without knowing about each
/// other.
class _RibbonPainter extends CustomPainter {
  _RibbonPainter({
    required this.prevX,
    required this.x,
    required this.nextX,
    required this.litIn,
    required this.litOut,
    required this.color,
    required this.nextColor,
    required this.first,
    required this.last,
  });

  final double prevX, x, nextX;
  final bool litIn, litOut, first, last;
  final Color color, nextColor;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    if (!first) {
      _stroke(
        canvas,
        Path()
          ..moveTo(prevX, 0)
          ..cubicTo(prevX, h * 0.25, x, h * 0.25, x, h / 2),
        litIn,
        color,
      );
    }
    if (!last) {
      _stroke(
        canvas,
        Path()
          ..moveTo(x, h / 2)
          ..cubicTo(x, h * 0.75, nextX, h * 0.75, nextX, h),
        litOut,
        nextColor,
      );
    }
  }

  /// Lit lengths get a coloured glow under a bright core; the rest is frosted
  /// glass with a dotted centre line, so the ribbon itself shows progress.
  void _stroke(Canvas canvas, Path path, bool lit, Color tint) {
    if (lit) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 22
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9)
          ..color = tint.withValues(alpha: 0.45),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: lit ? 0.92 : 0.55),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..color = lit
            ? tint.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.42),
    );
    if (!lit) {
      // Dotted centre line for the stretch still to come.
      for (final metric in path.computeMetrics()) {
        for (var d = 7.0; d < metric.length; d += 16) {
          final tan = metric.getTangentForOffset(d);
          if (tan == null) continue;
          canvas.drawCircle(
            tan.position,
            2.6,
            Paint()..color = AppColors.label.withValues(alpha: 0.55),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_RibbonPainter old) =>
      old.prevX != prevX ||
      old.x != x ||
      old.nextX != nextX ||
      old.litIn != litIn ||
      old.litOut != litOut ||
      old.color != color;
}

// ------------------------------------------------------------------- stops

/// A world stop: a soft clay orb inside a progress ring, with a number badge,
/// a crown once perfected, and a pulse + confetti burst on the current world.
class _WorldStop extends StatefulWidget {
  const _WorldStop({
    required this.section,
    required this.unlocked,
    required this.current,
    required this.progress,
    required this.perfected,
    required this.diameter,
    required this.confetti,
    required this.onTap,
  });

  final GameSection section;
  final bool unlocked;
  final bool current;
  final double progress;
  final bool perfected;
  final double diameter;
  final ConfettiController? confetti;
  final VoidCallback? onTap;

  @override
  State<_WorldStop> createState() => _WorldStopState();
}

class _WorldStopState extends State<_WorldStop> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.section;
    final d = widget.diameter;
    final base = widget.unlocked ? s.gradient : AppColors.lockedCard;
    final shade = widget.unlocked ? s.shadow : AppColors.lockedShadow;

    Widget orb = Container(
      width: d - 26,
      height: d - 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.4, -0.5),
          radius: 1.1,
          colors: [
            Color.lerp(base.first, Colors.white, 0.35)!,
            base.first,
            base.last,
          ],
          stops: const [0, 0.45, 1],
        ),
        boxShadow: [
          // Deep soft shadow plus a light rim: the clay look.
          BoxShadow(
            color: shade.withValues(alpha: 0.5),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.75),
            blurRadius: 10,
            spreadRadius: -6,
            offset: const Offset(-4, -5),
          ),
        ],
      ),
      child: Center(
        // Locked worlds stay a mystery — hide the themed emoji until then.
        child: widget.unlocked
            ? Text(s.emoji, style: const TextStyle(fontSize: 26))
            : Icon(
                Icons.lock_rounded,
                size: 24,
                color: Colors.white.withValues(alpha: 0.95),
              ),
      ),
    );

    if (widget.current) {
      orb = orb
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(end: 1.06, duration: 1100.ms, curve: Curves.easeInOut);
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
        scale: _down ? 0.92 : 1,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: SizedBox(
          width: d,
          height: d,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (widget.confetti != null)
                ConfettiWidget(
                  confettiController: widget.confetti!,
                  blastDirectionality: BlastDirectionality.explosive,
                  emissionFrequency: 0,
                  numberOfParticles: 14,
                  maxBlastForce: 14,
                  minBlastForce: 6,
                  gravity: 0.35,
                  shouldLoop: false,
                  colors: const [
                    AppColors.pink,
                    AppColors.amberLight,
                    AppColors.mintLight,
                    Colors.white,
                  ],
                ),
              CircularPercentIndicator(
                radius: d / 2,
                lineWidth: 6,
                percent: widget.progress.clamp(0.0, 1.0),
                circularStrokeCap: CircularStrokeCap.round,
                animation: true,
                animationDuration: 900,
                backgroundColor: Colors.white.withValues(alpha: 0.5),
                linearGradient: LinearGradient(
                  colors: widget.unlocked ? s.gradient : AppColors.lockedCard,
                ),
                center: orb,
              ),
              // World number badge.
              Positioned(
                bottom: -2,
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
                        color: Colors.black.withValues(alpha: 0.16),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${s.index + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: shade,
                    ),
                  ),
                ),
              ),
              if (widget.perfected)
                const Positioned(
                  top: -14,
                  child: Text('👑', style: TextStyle(fontSize: 20)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------- cards

/// The frosted card beside each stop: name, level progress and stars, plus a
/// play button on the world the player is on.
class _WorldCard extends StatefulWidget {
  const _WorldCard({
    required this.section,
    required this.unlocked,
    required this.current,
    required this.done,
    required this.stars,
    required this.onTap,
  });

  final GameSection section;
  final bool unlocked;
  final bool current;
  final int done;
  final int stars;
  final VoidCallback? onTap;

  @override
  State<_WorldCard> createState() => _WorldCardState();
}

class _WorldCardState extends State<_WorldCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.section;
    final maxStars = s.count * 3;

    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: widget.unlocked ? 0.44 : 0.3),
            borderRadius: BorderRadius.circular(24),
            border: GradientBoxBorder(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.95),
                  Colors.white.withValues(alpha: 0.2),
                ],
              ),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: (widget.unlocked ? s.shadow : AppColors.lockedShadow)
                    .withValues(alpha: 0.22),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (!widget.unlocked) ...[
                    Icon(
                      Icons.lock_rounded,
                      size: 14,
                      color: AppColors.muted.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 5),
                  ],
                  Expanded(
                    child: Text(
                      // Locked worlds keep their theme a surprise.
                      widget.unlocked ? s.name : 'Locked',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        color: widget.unlocked ? s.shadow : AppColors.muted,
                      ),
                    ),
                  ),
                  if (widget.current)
                    Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.pinkLight, AppColors.pink],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'NOW',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.7,
                              color: Colors.white,
                            ),
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scaleXY(
                          end: 1.1,
                          duration: 780.ms,
                          curve: Curves.easeInOut,
                        ),
                ],
              ),
              const SizedBox(height: 9),
              if (widget.unlocked) ...[
                LinearPercentIndicator(
                  percent: s.count == 0
                      ? 0
                      : (widget.done / s.count).clamp(0.0, 1.0),
                  lineHeight: 8,
                  barRadius: const Radius.circular(8),
                  padding: EdgeInsets.zero,
                  animation: true,
                  animationDuration: 800,
                  backgroundColor: Colors.white.withValues(alpha: 0.6),
                  linearGradient: LinearGradient(colors: s.gradient),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 15,
                      color: AppColors.amber,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${widget.stars}/$maxStars',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.body,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${widget.done}/${s.count} levels',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted.withValues(alpha: 0.95),
                      ),
                    ),
                  ],
                ),
                if (widget.current) ...[
                  const SizedBox(height: 11),
                  _PlayButton(section: s, onTap: widget.onTap),
                ],
              ] else
                Text(
                  'Unlocks at level ${s.start + 1}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    // A slow light sweep marks the world the player is on.
    if (widget.current) {
      card = card
          .animate(onPlay: (c) => c.repeat(period: 3000.ms))
          .shimmer(
            delay: 900.ms,
            duration: 1400.ms,
            color: Colors.white.withValues(alpha: 0.55),
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
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: card,
      ),
    );
  }
}

/// The candy call-to-action inside the current world's card.
class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.section, required this.onTap});

  final GameSection section;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: section.gradient,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white, width: 1.8),
          boxShadow: [
            BoxShadow(
              color: section.shadow.withValues(alpha: 0.5),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
            SizedBox(width: 4),
            Text(
              'PLAY',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ pieces

/// The floating pill that scrolls the journey back to the player's world.
class _ContinuePill extends StatelessWidget {
  const _ContinuePill({required this.section, required this.onTap});

  final GameSection section;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 11, 20, 13),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: section.gradient,
          ),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: section.shadow.withValues(alpha: 0.5),
              blurRadius: 16,
              offset: const Offset(0, 7),
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
              'Back to ${section.name}',
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
          color: Colors.white.withValues(alpha: 0.7),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.85),
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

/// A candy "sticker" heading: thick white outline, pink-to-amber gradient fill
/// and a soft drop shadow — the same look as the in-game praise words, so the
/// whole app shares one voice.
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
