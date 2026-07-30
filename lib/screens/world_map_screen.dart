import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../game/sections.dart';
import '../state/game_state.dart';
import '../widgets/liquid_glass.dart';
import 'game_screen.dart';

/// A single world's level picker — a clean, glossy **grid of level tiles**
/// (number + earned stars), themed in the world's colour. Tapping a tile opens
/// that level. (The winding road look is reserved for the Worlds trail.)
class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({super.key, required this.section});

  final GameSection section;

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  final ScrollController _scroll = ScrollController();

  static const double _pad = 28;
  static const double _gap = 24;
  static const double _aspect = 1.0; // circular glass bubbles

  /// Adaptive column count so bubbles stay a comfortable size on phones
  /// and tablets alike.
  static int _colsFor(double width) => width >= 900
      ? 6
      : width >= 600
      ? 5
      : 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final state = GameScope.read(context);
      final local = state.unlocked - widget.section.start;
      if (local < 0 || local >= widget.section.count) return;
      final width = MediaQuery.sizeOf(context).width;
      final cols = _colsFor(width);
      // The grid lives inside the glass panel (14dp side margins, capped at
      // 700dp on tablets) — mirror that here so the row math stays correct.
      final gridW = math.min(700.0, width - 28.0);
      final tileW = (gridW - _pad * 2 - _gap * (cols - 1)) / cols;
      final rowH = tileW / _aspect + _gap;
      final row = local ~/ cols;
      final target = row * rowH - _scroll.position.viewportDimension / 2;
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
    final size = MediaQuery.sizeOf(context);
    // Keep the glass panel clear of the frosting ledge painted along the
    // bottom of the artwork.
    final bottomMargin = size.height * 0.11 + 12;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // World-tinted gradient fallback underneath the artwork.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  s.gradient.first.withValues(alpha: 0.55),
                  s.gradient.last.withValues(alpha: 0.22),
                  AppColors.bg.last,
                ],
                stops: const [0, 0.45, 1],
              ),
            ),
          ),
          Image.asset(
            'assets/boba/levelbg.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          SafeArea(
            child: Column(
              children: [
                _header(s, state),
                Expanded(
                  // Cap grid width so tiles stay tidy on tablets.
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      // The bubbles float inside one big Liquid-Glass panel —
                      // the same "stage" treatment as the in-game board.
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(14, 32, 14, bottomMargin),
                        child: LiquidGlass(
                          radius: 28,
                          blur: 4,
                          opacity: 0.10,
                          child: GridView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.fromLTRB(
                              _pad,
                              18,
                              _pad,
                              22,
                            ),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: _colsFor(size.width),
                                  mainAxisSpacing: _gap,
                                  crossAxisSpacing: _gap,
                                  childAspectRatio: _aspect,
                                ),
                            itemCount: s.count,
                            itemBuilder: (context, i) {
                              final global = s.start + i;
                              final locked = !state.isUnlocked(global);
                              return _LevelBubble(
                                number: global + 1,
                                stars: state.starsFor(global),
                                locked: locked,
                                current: global == state.unlocked && !locked,
                                tint: s.gradient.last,
                                shadow: s.shadow,
                                onTap: locked
                                    ? null
                                    : () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              GameScreen(level: global),
                                        ),
                                      ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
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
            const SizedBox(width: 10),
            // World emoji orb in the world's colours.
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.35, -0.45),
                  radius: 1.15,
                  colors: [s.gradient.first, s.gradient.last],
                ),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: s.shadow.withValues(alpha: 0.45),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(s.emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'WORLD ${s.index + 1} · $done/${s.count} DONE',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: s.shadow,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                      color: AppColors.heading,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Stars earned in this world.
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
                  Text(
                    '$stars',
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
}

/// A circular Liquid-Glass level bubble — the brand surface applied to the
/// level picker. Completed levels are candy-tinted glass in the world's
/// colour, the next level is clear glass with a pulsing accent ring and a
/// PLAY label, and locked levels are dim frosted glass.
///
/// `blur: 0` keeps the 15-bubble grid cheap: the translucent fill + sheen
/// still reads as glass without a BackdropFilter per tile.
class _LevelBubble extends StatefulWidget {
  const _LevelBubble({
    required this.number,
    required this.stars,
    required this.locked,
    required this.current,
    required this.tint,
    required this.shadow,
    required this.onTap,
  });

  final int number;
  final int stars;
  final bool locked;
  final bool current;

  /// World colour used to tint completed bubbles.
  final Color tint;
  final Color shadow;
  final VoidCallback? onTap;

  @override
  State<_LevelBubble> createState() => _LevelBubbleState();
}

class _LevelBubbleState extends State<_LevelBubble>
    with SingleTickerProviderStateMixin {
  bool _down = false;
  AnimationController? _glow;

  @override
  void initState() {
    super.initState();
    _syncGlow();
  }

  @override
  void didUpdateWidget(covariant _LevelBubble old) {
    super.didUpdateWidget(old);
    if (old.current != widget.current) _syncGlow();
  }

  /// The pulsing glow runs only while this bubble is the current level.
  void _syncGlow() {
    if (widget.current && _glow == null) {
      _glow = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      )..repeat(reverse: true);
    } else if (!widget.current && _glow != null) {
      _glow!.dispose();
      _glow = null;
    }
  }

  @override
  void dispose() {
    _glow?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completed = widget.stars > 0;

    Widget bubble = LiquidGlass(
      // Far larger than any cell's half-side, so the square cell clips to a
      // perfect circle.
      radius: 200,
      blur: 0,
      opacity: widget.locked ? 0.32 : 0.55,
      tint: !widget.locked && completed ? widget.tint : null,
      shadow: !widget.locked,
      child: SizedBox.expand(
        child: widget.locked
            ? Icon(
                Icons.lock_rounded,
                color: AppColors.muted.withValues(alpha: 0.75),
                size: 22,
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${widget.number}',
                    style: TextStyle(
                      fontSize: 23,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      color: completed ? Colors.white : AppColors.heading,
                      shadows: completed
                          ? [
                              Shadow(
                                color: widget.shadow.withValues(alpha: 0.6),
                                offset: const Offset(0, 1),
                                blurRadius: 3,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (widget.current)
                    const Text(
                      'PLAY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppColors.accent,
                      ),
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < 3; i++)
                          Icon(
                            Icons.star_rounded,
                            size: 11,
                            color: i < widget.stars
                                ? (completed
                                      ? Colors.white
                                      : const Color(0xFFFFB020))
                                : (completed
                                      ? Colors.white.withValues(alpha: 0.35)
                                      : AppColors.muted.withValues(
                                          alpha: 0.35,
                                        )),
                          ),
                      ],
                    ),
                ],
              ),
      ),
    );

    // Accent ring + breathing glow around the current level.
    if (widget.current) {
      bubble = Stack(
        fit: StackFit.expand,
        children: [
          if (_glow != null)
            AnimatedBuilder(
              animation: _glow!,
              builder: (_, __) => DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(
                        alpha: 0.3 + 0.3 * _glow!.value,
                      ),
                      blurRadius: 14 + 8 * _glow!.value,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          bubble,
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accent, width: 2.4),
              ),
            ),
          ),
        ],
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
        scale: _down ? 0.9 : 1,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: bubble,
      ),
    );
  }
}
