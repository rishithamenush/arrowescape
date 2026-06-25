import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../state/game_state.dart';
import '../widgets/app_background.dart';
import '../widgets/app_logo.dart';
import '../widgets/hud.dart';
import 'daily_challenge_screen.dart';
import 'game_screen.dart';
import 'level_select_screen.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';

/// Main menu: logo, Play (resume), and entry points to every feature.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = GameScope.of(context);
    final p = state.progress;

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
                  children: [
                    // Top bar: coins + streak + settings.
                    Row(
                      children: [
                        StatPill(
                          icon: Icons.monetization_on_rounded,
                          label: '${p.coins}',
                          color: AppColors.coin,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        StatPill(
                          icon: Icons.local_fire_department_rounded,
                          label: '${p.streak}',
                          color: AppColors.danger,
                        ),
                        const Spacer(),
                        RoundIconButton(
                          icon: Icons.settings_rounded,
                          onTap: () => _push(context, const SettingsScreen()),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const AppLogo(size: 112),
                    const SizedBox(height: AppSpacing.md),
                    const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'ARROW ESCAPE',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${p.totalStars} ⭐ collected  •  Level ${p.currentLevel}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const Spacer(),
                    PrimaryButton(
                      label: 'PLAY',
                      icon: Icons.play_arrow_rounded,
                      expand: true,
                      onTap: () =>
                          _push(context, GameScreen(levelId: p.currentLevel)),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _MenuCard(
                            icon: Icons.grid_view_rounded,
                            label: 'Levels',
                            color: AppColors.primary,
                            onTap: () =>
                                _push(context, const LevelSelectScreen()),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _MenuCard(
                            icon: Icons.calendar_today_rounded,
                            label: 'Daily',
                            color: AppColors.success,
                            onTap: () =>
                                _push(context, const DailyChallengeScreen()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _MenuCard(
                      icon: Icons.shopping_bag_rounded,
                      label: 'Shop',
                      color: AppColors.secondary,
                      wide: true,
                      onTap: () => _push(context, const ShopScreen()),
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

  static void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.wide = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return GameButton(
      color: color,
      onTap: onTap,
      depth: 6,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.md,
      ),
      child: wide
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _iconBadge(icon),
                const SizedBox(width: AppSpacing.md),
                Text(label, style: _labelStyle),
              ],
            )
          : Column(
              children: [
                _iconBadge(icon),
                const SizedBox(height: AppSpacing.sm),
                Text(label, style: _labelStyle),
              ],
            ),
    );
  }

  static const _labelStyle = TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: 16,
    color: Colors.white,
  );

  Widget _iconBadge(IconData icon) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Icon(icon, color: Colors.white, size: 24),
  );
}
