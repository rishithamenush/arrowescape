import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../game/sections.dart';
import '../state/game_state.dart';
import '../widgets/candy.dart';
import 'world_map_screen.dart';

/// The "Worlds" overview: a scrollable list of richly-styled world cards that
/// open into a winding road map.
class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  final ScrollController _scroll = ScrollController();
  late final List<GameSection> _sections = buildSections();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final state = GameScope.read(context);
      final current = state.unlocked ~/ kSectionSize;
      const cardExtent = 156.0;
      final target =
          current * cardExtent - _scroll.position.viewportDimension / 3;
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
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
                itemCount: _sections.length,
                itemBuilder: (context, i) =>
                    _WorldCard(section: _sections[i], state: state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(GameState state) {
    final total = state.progress.fold<int>(0, (s, v) => s + v);
    final maxStars = state.progress.length * 3;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
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
          // White banner with title + a gold stars chip.
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
                          'Pick a world to play',
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
                  // Gold stars chip.
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
}

class _WorldCard extends StatefulWidget {
  const _WorldCard({required this.section, required this.state});

  final GameSection section;
  final GameState state;

  @override
  State<_WorldCard> createState() => _WorldCardState();
}

class _WorldCardState extends State<_WorldCard> {
  bool _down = false;
  static const double _depth = 8;

  @override
  Widget build(BuildContext context) {
    final s = widget.section;
    final state = widget.state;
    final unlocked = state.isUnlocked(s.start);

    var completed = 0;
    var stars = 0;
    for (var l = s.start; l <= s.end; l++) {
      if (state.starsFor(l) > 0) completed++;
      stars += state.starsFor(l);
    }
    final maxStars = s.count * 3;
    final isCurrent = state.unlocked >= s.start && state.unlocked <= s.end;
    final perfected = completed == s.count && stars == maxStars;
    final progress = s.count == 0 ? 0.0 : completed / s.count;

    final gradient = unlocked ? s.gradient : AppColors.lockedCard;
    final shadow = unlocked ? s.shadow : AppColors.lockedShadow;
    final press = _down ? _depth - 2 : 0.0;
    final br = BorderRadius.circular(28);

    void setDown(bool v) => setState(() => _down = v);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: GestureDetector(
        onTapDown: unlocked ? (_) => setDown(true) : null,
        onTapUp: unlocked ? (_) => setDown(false) : null,
        onTapCancel: () => setDown(false),
        onTap: unlocked
            ? () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => WorldMapScreen(section: s)),
              )
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 60),
          curve: Curves.easeOut,
          height: 138,
          transform: Matrix4.translationValues(0, press, 0),
          decoration: BoxDecoration(
            borderRadius: br,
            boxShadow: [
              BoxShadow(color: shadow, offset: Offset(0, _depth - press)),
              BoxShadow(
                color: shadow.withValues(alpha: 0.45),
                offset: Offset(0, _depth + 6 - press),
                blurRadius: 16,
              ),
              if (perfected)
                const BoxShadow(
                  color: Color(0x66FFD23F),
                  blurRadius: 22,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: br,
            child: Stack(
              children: [
                // Gradient face.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: gradient,
                      ),
                    ),
                  ),
                ),
                // Big faded emoji watermark.
                Positioned(
                  right: -18,
                  bottom: -24,
                  child: Opacity(
                    opacity: unlocked ? 0.22 : 0.12,
                    child: Transform.rotate(
                      angle: -0.25,
                      child: Text(
                        s.emoji,
                        style: const TextStyle(fontSize: 130),
                      ),
                    ),
                  ),
                ),
                // Top gloss.
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: FractionallySizedBox(
                      heightFactor: 0.45,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.28),
                              Colors.white.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Content.
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _Medallion(
                        number: s.index + 1,
                        progress: progress,
                        unlocked: unlocked,
                        perfected: perfected,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _info(
                          s,
                          unlocked,
                          isCurrent,
                          completed,
                          stars,
                          maxStars,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        unlocked
                            ? Icons.chevron_right_rounded
                            : Icons.lock_rounded,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 26,
                      ),
                    ],
                  ),
                ),
                // "Playing now" ribbon.
                if (isCurrent)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'PLAYING',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: s.shadow,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _info(
    GameSection s,
    bool unlocked,
    bool isCurrent,
    int completed,
    int stars,
    int maxStars,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'WORLD ${s.index + 1}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        Text(
          s.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 21,
            height: 1.05,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          unlocked
              ? 'Levels ${s.start + 1}–${s.end + 1}'
              : 'Unlock at level ${s.start + 1}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text(
              '★',
              style: TextStyle(fontSize: 15, color: Color(0xFFFFE08A)),
            ),
            const SizedBox(width: 3),
            Text(
              '$stars / $maxStars',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$completed/${s.count} done',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Glossy circular world medallion with a star/levels progress ring.
class _Medallion extends StatelessWidget {
  const _Medallion({
    required this.number,
    required this.progress,
    required this.unlocked,
    required this.perfected,
  });

  final int number;
  final double progress;
  final bool unlocked;
  final bool perfected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 74,
      height: 74,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(74, 74),
            painter: _RingPainter(progress: unlocked ? progress : 0),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.4),
                colors: [
                  Colors.white.withValues(alpha: 0.55),
                  Colors.white.withValues(alpha: 0.18),
                ],
              ),
            ),
            child: Center(
              child: unlocked
                  ? Text(
                      '$number',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Color(0x33000000),
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    )
                  : const Icon(
                      Icons.lock_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
            ),
          ),
          if (perfected)
            const Positioned(
              top: -2,
              child: Text('👑', style: TextStyle(fontSize: 22)),
            ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 3;
    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawCircle(center, radius, track);

    if (progress > 0) {
      final arc = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress.clamp(0, 1),
        false,
        arc,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}
