import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'hud.dart';

/// Win overlay: animated stars, coin reward and Next / Replay / Home.
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
    return _DialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Level Complete!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          StarRow(count: stars, size: 48, animate: true),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.monetization_on_rounded,
                color: AppColors.coin,
                size: 26,
              ),
              const SizedBox(width: 8),
              Text(
                '+$coins',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.coin,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Next Level',
            icon: Icons.play_arrow_rounded,
            onTap: onNext,
            expand: true,
            color: AppColors.success,
          ),
          const SizedBox(height: AppSpacing.sm),
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
              const SizedBox(width: AppSpacing.sm),
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
      ),
    );
  }
}

/// Stuck overlay: no moves left — offer Undo / Restart / Hint / ad-continue.
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
    return _DialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.sentiment_dissatisfied_rounded,
            color: AppColors.warning,
            size: 56,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'No moves left',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Every arrow is blocked. Undo a move or restart the level.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (canUndo)
            PrimaryButton(
              label: 'Undo last move',
              icon: Icons.undo_rounded,
              onTap: onUndo,
              expand: true,
            ),
          const SizedBox(height: AppSpacing.sm),
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
              const SizedBox(width: AppSpacing.sm),
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
      ),
    );
  }
}

class _DialogShell extends StatelessWidget {
  const _DialogShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;
    // showGeneralDialog does not provide a Material ancestor, so without this
    // the Text widgets render with the unstyled fallback (huge text + yellow
    // underlines). A transparent Material supplies the theme's text style.
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.85, end: 1),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          builder: (_, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Container(
            margin: const EdgeInsets.all(AppSpacing.xl),
            padding: const EdgeInsets.all(AppSpacing.xl),
            constraints: BoxConstraints(maxWidth: 380, maxHeight: maxHeight),
            decoration: AppTheme.card(radius: AppSpacing.radiusLg),
            // Scrolls instead of overflowing on small screens / large fonts.
            child: SingleChildScrollView(child: child),
          ),
        ),
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
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
