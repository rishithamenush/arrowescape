import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../logic/level_loader.dart';
import '../state/game_state.dart';
import '../widgets/app_background.dart';
import '../widgets/hud.dart';
import 'game_screen.dart';

/// Scrollable, world-grouped grid of levels showing lock / star state.
class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key});

  static const _worldNames = ['Meadow', 'Desert', 'Glacier', 'Volcano'];
  static const _worldColors = [
    AppColors.success,
    AppColors.warning,
    AppColors.primary,
    AppColors.danger,
  ];

  @override
  Widget build(BuildContext context) {
    final state = GameScope.of(context);
    final p = state.progress;

    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            _Header(coins: p.coins, totalStars: p.totalStars),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                itemCount: LevelLoader.worldCount,
                itemBuilder: (context, world) {
                  final start = world * LevelLoader.worldSize + 1;
                  return _WorldSection(
                    title: _worldNames[world % _worldNames.length],
                    color: _worldColors[world % _worldColors.length],
                    startId: start,
                    count: LevelLoader.worldSize,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.coins, required this.totalStars});
  final int coins;
  final int totalStars;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          RoundIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Text(
              'Levels',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          StatPill(
            icon: Icons.star_rounded,
            label: '$totalStars',
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }
}

class _WorldSection extends StatelessWidget {
  const _WorldSection({
    required this.title,
    required this.color,
    required this.startId,
    required this.count,
  });

  final String title;
  final Color color;
  final int startId;
  final int count;

  @override
  Widget build(BuildContext context) {
    final state = GameScope.of(context);
    final p = state.progress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            children: [
              Container(width: 6, height: 22, color: color),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          // Max-extent delegate adapts the column count to the screen width
          // (more columns on tablets, fewer on small phones).
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 76,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1,
          ),
          itemCount: count,
          itemBuilder: (context, i) {
            final id = startId + i;
            return _LevelTile(
              id: id,
              color: color,
              stars: p.starsFor(id),
              unlocked: p.isUnlocked(id),
            );
          },
        ),
      ],
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.id,
    required this.color,
    required this.stars,
    required this.unlocked,
  });

  final int id;
  final Color color;
  final int stars;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final completed = stars > 0;
    return GestureDetector(
      onTap: unlocked
          ? () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => GameScreen(levelId: id)))
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: unlocked
              ? (completed ? color.withValues(alpha: 0.22) : AppColors.surface)
              : AppColors.surface.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          border: Border.all(
            color: unlocked ? color.withValues(alpha: 0.5) : Colors.white10,
          ),
        ),
        child: unlocked
            ? FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$id',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      _MiniStars(stars: stars, color: color),
                    ],
                  ),
                ),
              )
            : const Icon(
                Icons.lock_rounded,
                color: AppColors.textMuted,
                size: 22,
              ),
      ),
    );
  }
}

class _MiniStars extends StatelessWidget {
  const _MiniStars({required this.stars, required this.color});
  final int stars;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final earned = i < stars;
        return Icon(
          earned ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 11,
          color: earned ? AppColors.warning : AppColors.textMuted,
        );
      }),
    );
  }
}
