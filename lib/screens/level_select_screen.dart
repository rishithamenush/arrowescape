import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../game/levels.dart';
import '../state/game_state.dart';
import '../widgets/candy.dart';
import 'game_screen.dart';

class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = GameScope.of(context);

    return Scaffold(
      body: CandyBackground(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                    'Select Level',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: AppColors.heading,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemCount: kLevels.length,
                  itemBuilder: (context, i) => _LevelCard(
                    index: i,
                    locked: !state.isUnlocked(i),
                    stars: state.starsFor(i),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.index,
    required this.locked,
    required this.stars,
  });

  final int index;
  final bool locked;
  final int stars;

  @override
  Widget build(BuildContext context) {
    final gradient = locked
        ? AppColors.lockedCard
        : AppColors.levelCards[index % AppColors.levelCards.length];
    final shadow = locked
        ? AppColors.lockedShadow
        : AppColors.levelShadow[index % AppColors.levelShadow.length];
    final starsText = stars > 0
        ? '★★★'.substring(0, stars) + '✩✩✩'.substring(0, 3 - stars)
        : '✩✩✩';

    return CandyButton(
      gradient: gradient,
      shadow: shadow,
      radius: 24,
      depth: 6,
      padding: EdgeInsets.zero,
      onTap: locked
          ? () {}
          : () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => GameScreen(level: index))),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'LEVEL',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  color: Color(0xCCFFFFFF),
                ),
              ),
              Text(
                '${index + 1}',
                style: const TextStyle(
                  fontSize: 48,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                starsText,
                style: const TextStyle(
                  fontSize: 18,
                  letterSpacing: 3,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          if (locked)
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0x8C3C2846)),
                child: Center(
                  child: Text('🔒', style: TextStyle(fontSize: 34)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
