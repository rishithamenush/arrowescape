import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'hud.dart';

/// Win overlay: a celebratory card with an overhanging trophy badge, animated
/// stars on a ribbon, a coin reward chip and candy action buttons.
class WinDialog extends StatelessWidget {
  const WinDialog({
    super.key,
    required this.stars,
    required this.coins,
    required this.onNext,
    required this.onReplay,
    required this.onHome,
  });

  final int stars;
  final int coins;
  final VoidCallback onNext;
  final VoidCallback onReplay;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return _PopupCard(
      accent: AppColors.success,
      badgeIcon: Icons.emoji_events_rounded,
      title: 'Level Complete!',
      children: [
        const SizedBox(height: AppSpacing.md),
        _StarRibbon(stars: stars),
        const SizedBox(height: AppSpacing.lg),
        _CoinChip(coins: coins),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: 'Next Level',
          icon: Icons.play_arrow_rounded,
          onTap: onNext,
          expand: true,
          color: AppColors.success,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _SecondaryButton(
                icon: Icons.refresh_rounded,
                label: 'Replay',
                color: AppColors.secondary,
                onTap: onReplay,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _SecondaryButton(
                icon: Icons.home_rounded,
                label: 'Home',
                color: AppColors.primary,
                onTap: onHome,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Stuck overlay: no moves left — offer Undo / Restart / Home.
class StuckDialog extends StatelessWidget {
  const StuckDialog({
    super.key,
    required this.onUndo,
    required this.onRestart,
    required this.onHint,
    required this.onHome,
    this.canUndo = true,
  });

  final VoidCallback onUndo;
  final VoidCallback onRestart;
  final VoidCallback onHint;
  final VoidCallback onHome;
  final bool canUndo;

  @override
  Widget build(BuildContext context) {
    return _PopupCard(
      accent: AppColors.warning,
      badgeIcon: Icons.sentiment_dissatisfied_rounded,
      title: 'No moves left',
      children: [
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Every arrow is blocked. Undo a move or restart the level.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (canUndo)
          PrimaryButton(
            label: 'Undo last move',
            icon: Icons.undo_rounded,
            onTap: onUndo,
            expand: true,
          ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _SecondaryButton(
                icon: Icons.refresh_rounded,
                label: 'Restart',
                color: AppColors.danger,
                onTap: onRestart,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _SecondaryButton(
                icon: Icons.home_rounded,
                label: 'Home',
                color: AppColors.primary,
                onTap: onHome,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Game-over overlay shown when the player runs out of hearts.
class GameOverDialog extends StatelessWidget {
  const GameOverDialog({
    super.key,
    required this.onRetry,
    required this.onHome,
  });

  final VoidCallback onRetry;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return _PopupCard(
      accent: AppColors.danger,
      badgeIcon: Icons.heart_broken_rounded,
      title: 'Out of Hearts!',
      children: [
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'You ran out of hearts. Try the level again!',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: 'Try Again',
          icon: Icons.refresh_rounded,
          onTap: onRetry,
          expand: true,
          color: AppColors.danger,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _SecondaryButton(
                icon: Icons.home_rounded,
                label: 'Home',
                color: AppColors.primary,
                onTap: onHome,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Shared popup chrome: a bouncing white card with a coloured header glow and
/// a circular badge that overhangs the top edge.
class _PopupCard extends StatelessWidget {
  const _PopupCard({
    required this.accent,
    required this.badgeIcon,
    required this.title,
    required this.children,
  });

  final Color accent;
  final IconData badgeIcon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.86;
    const badgeSize = 92.0;

    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1),
          duration: const Duration(milliseconds: 320),
          curve: Curves.elasticOut,
          builder: (_, scale, child) =>
              Transform.scale(scale: scale.clamp(0, 1.1), child: child),
          child: Container(
            margin: const EdgeInsets.all(AppSpacing.xl),
            constraints: BoxConstraints(maxWidth: 360, maxHeight: maxHeight),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // Card.
                Container(
                  margin: const EdgeInsets.only(top: badgeSize / 2),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    badgeSize / 2 + AppSpacing.lg,
                    AppSpacing.xl,
                    AppSpacing.xl,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.30),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        ...children,
                      ],
                    ),
                  ),
                ),
                // Overhanging badge.
                _Badge(icon: badgeIcon, accent: accent, size: badgeSize),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.accent, required this.size});

  final IconData icon;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(accent, Colors.white, 0.30)!,
            accent,
            Color.lerp(accent, Colors.black, 0.12)!,
          ],
        ),
        border: Border.all(color: Colors.white, width: 5),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.5),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.5),
    );
  }
}

/// Animated stars sitting on a soft coloured ribbon.
class _StarRibbon extends StatelessWidget {
  const _StarRibbon({required this.stars});
  final int stars;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(40),
      ),
      child: StarRow(count: stars, size: 46, animate: true),
    );
  }
}

/// Coin reward chip.
class _CoinChip extends StatelessWidget {
  const _CoinChip({required this.coins});
  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.coin.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.monetization_on_rounded,
            color: AppColors.coin,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            '+$coins',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFFD9A400),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GameButton(
      color: color,
      onTap: onTap,
      expand: true,
      depth: 5,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon inside a soft translucent circle for a premium, intentional
          // look that matches the badge / menu styling.
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
