import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../state/game_state.dart';
import '../widgets/app_background.dart';
import '../widgets/hud.dart';
import 'game_screen.dart';

/// One special puzzle per day with a 7-day streak / reward calendar.
class DailyChallengeScreen extends StatelessWidget {
  const DailyChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = GameScope.of(context);
    final p = state.progress;
    final now = DateTime.now();
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Scaffold(
      body: AppBackground(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - AppSpacing.lg * 2,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        RoundIconButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        const Flexible(
                          child: Text(
                            'Daily Challenge',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.success, AppColors.primary],
                        ),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.local_fire_department_rounded,
                            color: Colors.white,
                            size: 48,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            '${p.streak}-day streak',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Play every day for bigger rewards',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Text(
                      'This week',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: List.generate(7, (i) {
                        final claimed = i < (now.weekday);
                        final isToday = i == now.weekday - 1;
                        return Expanded(
                          child: _DayChip(
                            label: weekdays[i],
                            claimed: claimed,
                            isToday: isToday,
                            reward: 20 + i * 10,
                          ),
                        );
                      }),
                    ),
                    const Spacer(),
                    PrimaryButton(
                      label: "Play today's puzzle",
                      icon: Icons.play_arrow_rounded,
                      expand: true,
                      color: AppColors.success,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const GameScreen(levelId: -1, daily: true),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.claimed,
    required this.isToday,
    required this.reward,
  });

  final String label;
  final bool claimed;
  final bool isToday;
  final int reward;

  @override
  Widget build(BuildContext context) {
    // Sized by the surrounding Expanded so seven chips always fit any width.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 44, maxHeight: 44),
              decoration: BoxDecoration(
                color: claimed
                    ? AppColors.success.withValues(alpha: 0.25)
                    : AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isToday ? AppColors.warning : Colors.white12,
                  width: isToday ? 2 : 1,
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    claimed
                        ? Icons.check_rounded
                        : Icons.monetization_on_rounded,
                    color: claimed ? AppColors.success : AppColors.coin,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
