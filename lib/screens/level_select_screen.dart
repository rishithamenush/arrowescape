import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../game/sections.dart';
import '../state/game_state.dart';
import '../widgets/candy.dart';
import 'world_map_screen.dart';

/// The "Worlds" overview: a scrollable list of themed section cards, each
/// showing progress, that opens into a winding road map.
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
    // Scroll to the world the player is currently on.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final state = GameScope.read(context);
      final current = state.unlocked ~/ kSectionSize;
      const cardExtent = 124.0;
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
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
                itemCount: _sections.length,
                itemBuilder: (context, i) =>
                    _SectionCard(section: _sections[i], state: state),
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
            'Worlds',
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
                  '$total / $maxStars',
                  style: const TextStyle(
                    fontSize: 14,
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
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section, required this.state});

  final GameSection section;
  final GameState state;

  @override
  Widget build(BuildContext context) {
    final unlocked = state.isUnlocked(section.start);
    var completed = 0;
    var stars = 0;
    for (var l = section.start; l <= section.end; l++) {
      if (state.starsFor(l) > 0) completed++;
      stars += state.starsFor(l);
    }
    final isCurrent =
        state.unlocked >= section.start && state.unlocked <= section.end;
    final progress = section.count == 0 ? 0.0 : completed / section.count;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CandyButton(
        gradient: unlocked ? section.gradient : AppColors.lockedCard,
        shadow: unlocked ? section.shadow : AppColors.lockedShadow,
        radius: 26,
        depth: 7,
        padding: const EdgeInsets.all(16),
        onTap: unlocked
            ? () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => WorldMapScreen(section: section),
                ),
              )
            : () {},
        child: Row(
          children: [
            // Emoji badge.
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: unlocked
                    ? Text(section.emoji, style: const TextStyle(fontSize: 30))
                    : const Icon(
                        Icons.lock_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
              ),
            ),
            const SizedBox(width: 14),
            // Title + progress.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          section.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'PLAYING',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    unlocked
                        ? 'Levels ${section.start + 1}–${section.end + 1}'
                        : 'Reach level ${section.start + 1} to unlock',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Progress bar.
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              Container(
                                height: 8,
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                              FractionallySizedBox(
                                widthFactor: progress,
                                child: Container(
                                  height: 8,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$completed/${section.count}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (unlocked)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '★',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFFFE08A),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '$stars',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 6),
                Icon(
                  unlocked ? Icons.chevron_right_rounded : Icons.lock_rounded,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 26,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
