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
                    _PlayButton(
                      level: p.currentLevel,
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
                            subtitle: 'All worlds',
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
                            subtitle: 'New puzzle',
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
                      subtitle: 'Skins & boosters',
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

/// Big hero "PLAY" button with an icon disc and the current level.
class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.level, required this.onTap});

  final int level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GameButton(
      color: AppColors.success,
      onTap: onTap,
      expand: true,
      depth: 9,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.24),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PLAY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Level $level',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A premium menu tile: glossy icon badge, title, subtitle and (when [wide]) a
/// chevron. Vertical for the square tiles, horizontal for the wide one.
class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.wide = false,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return GameButton(
      color: color,
      onTap: onTap,
      depth: 7,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: wide
          ? Row(
              children: [
                _iconBadge(),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [_title(), _subtitle()],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.85),
                  size: 28,
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _iconBadge(),
                const SizedBox(height: AppSpacing.sm),
                _title(),
                const SizedBox(height: 1),
                _subtitle(),
              ],
            ),
    );
  }

  Widget _title() => Text(
    label,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: const TextStyle(
      fontWeight: FontWeight.w800,
      fontSize: 17,
      color: Colors.white,
    ),
  );

  Widget _subtitle() => Text(
    subtitle,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 12,
      color: Colors.white.withValues(alpha: 0.85),
    ),
  );

  Widget _iconBadge() => Container(
    width: 50,
    height: 50,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.32),
          Colors.white.withValues(alpha: 0.14),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
    ),
    child: Icon(icon, color: Colors.white, size: 26),
  );
}
