import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../game/sections.dart';
import '../state/game_state.dart';
import '../widgets/candy.dart';
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

  static const int _cols = 3;
  static const double _pad = 18;
  static const double _gap = 14;
  static const double _aspect = 0.86; // tile width / height

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final state = GameScope.read(context);
      final local = state.unlocked - widget.section.start;
      if (local < 0 || local >= widget.section.count) return;
      final width = MediaQuery.sizeOf(context).width;
      final tileW = (width - _pad * 2 - _gap * (_cols - 1)) / _cols;
      final rowH = tileW / _aspect + _gap;
      final row = local ~/ _cols;
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
                    s.gradient.first.withValues(alpha: 0.55),
                    s.gradient.last.withValues(alpha: 0.22),
                    AppColors.bg.last,
                  ],
                  stops: const [0, 0.45, 1],
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
                  child: GridView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(_pad, 6, _pad, 28),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _cols,
                          mainAxisSpacing: _gap,
                          crossAxisSpacing: _gap,
                          childAspectRatio: _aspect,
                        ),
                    itemCount: s.count,
                    itemBuilder: (context, i) {
                      final global = s.start + i;
                      final locked = !state.isUnlocked(global);
                      return _LevelTile(
                        number: global + 1,
                        stars: state.starsFor(global),
                        locked: locked,
                        current: global == state.unlocked && !locked,
                        gradient: locked ? AppColors.lockedCard : s.gradient,
                        shadow: locked ? AppColors.lockedShadow : s.shadow,
                        onTap: locked
                            ? null
                            : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => GameScreen(level: global),
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
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
            child: const LiquidGlass(
              radius: 16,
              blur: 14,
              child: SizedBox(
                width: 46,
                height: 46,
                child: Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.accent,
                  size: 30,
                ),
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
}

/// A single glossy level tile: number, three rating stars, lock / current state.
class _LevelTile extends StatefulWidget {
  const _LevelTile({
    required this.number,
    required this.stars,
    required this.locked,
    required this.current,
    required this.gradient,
    required this.shadow,
    required this.onTap,
  });

  final int number;
  final int stars;
  final bool locked;
  final bool current;
  final List<Color> gradient;
  final Color shadow;
  final VoidCallback? onTap;

  @override
  State<_LevelTile> createState() => _LevelTileState();
}

class _LevelTileState extends State<_LevelTile>
    with SingleTickerProviderStateMixin {
  bool _down = false;
  AnimationController? _glow;

  @override
  void initState() {
    super.initState();
    if (widget.current) {
      _glow = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _glow?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(18);
    final enabled = widget.onTap != null;

    Widget tile = GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.92 : 1,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: br,
            boxShadow: [
              BoxShadow(
                color: widget.shadow.withValues(alpha: 0.5),
                blurRadius: 8,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: br,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Themed gradient face.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.gradient,
                    ),
                  ),
                ),
                // Top gloss.
                Align(
                  alignment: Alignment.topCenter,
                  child: FractionallySizedBox(
                    heightFactor: 0.5,
                    widthFactor: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.32),
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Content.
                Center(
                  child: widget.locked
                      ? const Icon(
                          Icons.lock_rounded,
                          color: Colors.white,
                          size: 26,
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${widget.number}',
                              style: const TextStyle(
                                fontSize: 32,
                                height: 1,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Color(0x40000000),
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 7),
                            _stars(),
                          ],
                        ),
                ),
                // Glass rim.
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: br,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                  ),
                ),
                // Current-level bright ring.
                if (widget.current)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: br,
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    // Soft pulsing glow behind the current level.
    if (widget.current && _glow != null) {
      tile = AnimatedBuilder(
        animation: _glow!,
        builder: (_, child) => DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: br,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(
                  alpha: 0.25 + 0.45 * _glow!.value,
                ),
                blurRadius: 14 + 8 * _glow!.value,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        ),
        child: tile,
      );
    }

    return tile;
  }

  Widget _stars() {
    // Stars sit inside a soft pill so they read as a tidy rating badge.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final earned = i < widget.stars;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Icon(
              Icons.star_rounded,
              size: 16,
              color: earned
                  ? const Color(0xFFFFD23F)
                  : Colors.white.withValues(alpha: 0.4),
            ),
          );
        }),
      ),
    );
  }
}
