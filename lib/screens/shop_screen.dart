import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../state/game_state.dart';
import '../widgets/app_background.dart';
import '../widgets/hud.dart';

/// Spend coins (or watch a rewarded ad) on hints, undos and cosmetics.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = GameScope.of(context);
    final p = state.progress;

    void buy(String name, int price, VoidCallback grant) {
      if (state.spendCoins(price)) {
        grant();
        _snack(context, 'Purchased $name');
      } else {
        _snack(context, 'Not enough coins');
      }
    }

    return Scaffold(
      body: AppBackground(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
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
                  const Expanded(
                    child: Text(
                      'Shop',
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
                    icon: Icons.monetization_on_rounded,
                    label: '${p.coins}',
                    color: AppColors.coin,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: ListView(
                  children: [
                    const _SectionTitle('Boosters'),
                    _ShopItem(
                      icon: Icons.lightbulb_rounded,
                      color: AppColors.warning,
                      title: '5 Hints',
                      subtitle: 'Reveal a solvable arrow',
                      price: 80,
                      onBuy: () => buy('5 Hints', 80, () => state.addHints(5)),
                    ),
                    _ShopItem(
                      icon: Icons.undo_rounded,
                      color: AppColors.primary,
                      title: '5 Undos',
                      subtitle: 'Take back a move',
                      price: 80,
                      onBuy: () => buy('5 Undos', 80, () => state.addUndos(5)),
                    ),
                    _ShopItem(
                      icon: Icons.play_circle_fill_rounded,
                      color: AppColors.success,
                      title: 'Free hint',
                      subtitle: 'Watch a short video',
                      rewarded: true,
                      onBuy: () {
                        state.addHints(1);
                        _snack(context, 'Reward granted: +1 hint');
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _SectionTitle('Cosmetics'),
                    _ShopItem(
                      icon: Icons.palette_rounded,
                      color: AppColors.secondary,
                      title: 'Neon arrow skin',
                      subtitle: 'A glowing arrow set',
                      price: 250,
                      onBuy: () =>
                          buy('Neon skin', 250, () => state.setArrowSkin(1)),
                    ),
                    _ShopItem(
                      icon: Icons.dashboard_rounded,
                      color: AppColors.danger,
                      title: 'Sunset board theme',
                      subtitle: 'Warm board palette',
                      price: 250,
                      onBuy: () => buy(
                        'Sunset theme',
                        250,
                        () => state.setBoardTheme(1),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _SectionTitle('Coins'),
                    _ShopItem(
                      icon: Icons.block_rounded,
                      color: AppColors.textPrimary,
                      title: 'Remove ads',
                      subtitle: 'One-time purchase',
                      iap: '\$2.99',
                      onBuy: () => _snack(context, 'Launches store checkout'),
                    ),
                    _ShopItem(
                      icon: Icons.savings_rounded,
                      color: AppColors.coin,
                      title: 'Pile of 1000 coins',
                      subtitle: 'Best value',
                      iap: '\$4.99',
                      onBuy: () => _snack(context, 'Launches store checkout'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceAlt,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ShopItem extends StatelessWidget {
  const _ShopItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onBuy,
    this.price,
    this.iap,
    this.rewarded = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onBuy;
  final int? price;
  final String? iap;
  final bool rewarded;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppTheme.card(),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _buyButton(),
        ],
      ),
    );
  }

  Widget _buyButton() {
    final Color btnColor;
    final Widget label;
    if (rewarded) {
      btnColor = AppColors.success;
      label = const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
          SizedBox(width: 2),
          Text('Free', style: _btnText),
        ],
      );
    } else if (iap != null) {
      btnColor = AppColors.secondary;
      label = Text(iap!, style: _btnText);
    } else {
      btnColor = AppColors.coin;
      label = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.monetization_on_rounded,
            color: Colors.black87,
            size: 16,
          ),
          const SizedBox(width: 3),
          Text(
            '$price',
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: onBuy,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: btnColor,
          borderRadius: BorderRadius.circular(40),
        ),
        child: label,
      ),
    );
  }

  static const _btnText = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w800,
  );
}
