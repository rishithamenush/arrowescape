import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Scales its child down briefly while pressed for a tactile, game-like feel.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// A glossy, 3D "candy" button matching the arrow tiles: diagonal gradient
/// face, a raised top shine, a darker bottom edge for thickness, a soft
/// coloured glow and a press-bounce. Works as a pill, card or circle by
/// varying [radius]/[padding].
class GameButton extends StatelessWidget {
  const GameButton({
    super.key,
    required this.child,
    required this.onTap,
    this.color = AppColors.primary,
    this.radius = AppSpacing.radius,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.xl,
      vertical: AppSpacing.md,
    ),
    this.enabled = true,
    this.depth = 6,
    this.expand = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final double radius;
  final EdgeInsetsGeometry padding;
  final bool enabled;
  final double depth;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final dark = Color.lerp(color, Colors.black, 0.30)!;
    final light = Color.lerp(color, Colors.white, 0.24)!;
    final br = BorderRadius.circular(radius);

    return Pressable(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Container(
          width: expand ? double.infinity : null,
          decoration: BoxDecoration(
            borderRadius: br,
            boxShadow: [
              // 3D thickness (solid, no blur) + soft coloured glow.
              BoxShadow(color: dark, offset: Offset(0, depth)),
              BoxShadow(
                color: color.withValues(alpha: 0.40),
                offset: Offset(0, depth + 3),
                blurRadius: 14,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: br,
            child: Stack(
              children: [
                // Glossy gradient face.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          light,
                          color,
                          Color.lerp(color, Colors.black, 0.06)!,
                        ],
                        stops: const [0, 0.55, 1],
                      ),
                    ),
                  ),
                ),
                // Top shine.
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: FractionallySizedBox(
                      heightFactor: 0.5,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.32),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(padding: padding, child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A small rounded pill used for coin balance, move counter, streak, etc.
class StatPill extends StatelessWidget {
  const StatPill({
    super.key,
    required this.icon,
    required this.label,
    this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFF1F3FF)],
        ),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: (color ?? AppColors.primary).withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color ?? AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return pill;
    return Pressable(onTap: onTap, child: pill);
  }
}

/// Circular glossy icon button used for back / settings / pause.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color,
    this.background = AppColors.surface,
    this.badge,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final Color background;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GameButton(
          color: background,
          onTap: onTap,
          radius: 23,
          depth: 5,
          padding: EdgeInsets.zero,
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(icon, color: color ?? AppColors.textPrimary, size: 22),
          ),
        ),
        if (badge != null)
          Positioned(
            right: -2,
            top: -2,
            child: _Badge(text: badge!, color: AppColors.danger),
          ),
      ],
    );
  }
}

/// A labelled candy action button for the bottom bar (Undo / Hint / Restart).
class BoardActionButton extends StatelessWidget {
  const BoardActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.primary,
    this.enabled = true,
    this.count,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool enabled;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            GameButton(
              color: color,
              onTap: enabled ? onTap : null,
              enabled: enabled,
              radius: 30,
              depth: 6,
              padding: EdgeInsets.zero,
              child: SizedBox(
                width: 60,
                height: 60,
                child: Icon(icon, color: Colors.white, size: 27),
              ),
            ),
            if (count != null)
              Positioned(
                right: -4,
                top: -4,
                child: _Badge(
                  text: '$count',
                  color: Colors.white,
                  textColor: color,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Small rounded count / notification badge.
class _Badge extends StatelessWidget {
  const _Badge({
    required this.text,
    required this.color,
    this.textColor = Colors.white,
  });

  final String text;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 21, minHeight: 21),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }
}

/// Animated row of up to three stars.
class StarRow extends StatelessWidget {
  const StarRow({
    super.key,
    required this.count,
    this.size = 28,
    this.animate = false,
  });

  final int count;
  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final earned = i < count;
        final star = Icon(
          earned ? Icons.star_rounded : Icons.star_outline_rounded,
          color: earned ? AppColors.warning : AppColors.textMuted,
          size: size,
        );
        if (!animate || !earned) return star;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 300 + i * 180),
          curve: Curves.elasticOut,
          builder: (_, v, child) =>
              Transform.scale(scale: v.clamp(0, 1.2), child: child),
          child: star,
        );
      }),
    );
  }
}

/// Big primary call-to-action candy button used on menus and dialogs.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.color = AppColors.primary,
    this.expand = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final Color color;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return GameButton(
      color: color,
      onTap: onTap,
      expand: expand,
      depth: 7,
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
