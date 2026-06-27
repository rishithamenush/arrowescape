import 'package:flutter/material.dart';

import '../core/theme.dart';

/// The signature "chunky" candy button: a flat coloured face with a solid
/// bottom shadow that compresses (translateY) when pressed.
class CandyButton extends StatefulWidget {
  const CandyButton({
    super.key,
    required this.child,
    required this.onTap,
    this.gradient,
    this.color,
    this.shadow = AppColors.pinkShadow,
    this.radius = 18,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    this.depth = 6,
    this.expand = false,
  });

  final Widget child;
  final VoidCallback onTap;
  final List<Color>? gradient;
  final Color? color;
  final Color shadow;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double depth;
  final bool expand;

  @override
  State<CandyButton> createState() => _CandyButtonState();
}

class _CandyButtonState extends State<CandyButton> {
  bool _down = false;
  void _set(bool v) => setState(() => _down = v);

  @override
  Widget build(BuildContext context) {
    final press = _down ? widget.depth - 2 : 0.0;
    final br = BorderRadius.circular(widget.radius);
    final decoration = widget.gradient != null
        ? BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: widget.gradient!,
            ),
            borderRadius: br,
          )
        : BoxDecoration(color: widget.color, borderRadius: br);

    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        curve: Curves.easeOut,
        width: widget.expand ? double.infinity : null,
        transform: Matrix4.translationValues(0, press, 0),
        decoration: decoration.copyWith(
          boxShadow: [
            BoxShadow(
              color: widget.shadow,
              offset: Offset(0, widget.depth - press),
            ),
            BoxShadow(
              color: widget.shadow.withValues(alpha: 0.4),
              offset: Offset(0, widget.depth + 4 - press),
              blurRadius: 12,
            ),
          ],
        ),
        child: Padding(
          padding: widget.padding,
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}

/// Slow floating decorative bubbles used on menu backgrounds.
class FloatingBubbles extends StatefulWidget {
  const FloatingBubbles({super.key});

  @override
  State<FloatingBubbles> createState() => _FloatingBubblesState();
}

class _FloatingBubblesState extends State<FloatingBubbles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  static const _bubbles = [
    (0.06, 0.10, 120.0, Color(0xFFFF6F9D)),
    (0.78, 0.16, 150.0, Color(0xFFFFD23F)),
    (0.10, 0.80, 90.0, Color(0xFF44D0E6)),
    (0.80, 0.74, 70.0, Color(0xFF9B6BFF)),
  ];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, c) => AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            return Stack(
              children: [
                for (var i = 0; i < _bubbles.length; i++) _bubble(c, i),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _bubble(BoxConstraints c, int i) {
    final b = _bubbles[i];
    final phase = (_c.value * 2 * 3.14159) + i;
    final dy = -16 * (0.5 - 0.5 * (1 - 2 * (phase % 6.28 / 6.28 - 0.5).abs()));
    return Positioned(
      left: b.$1 * c.maxWidth - b.$3 / 2,
      top: b.$2 * c.maxHeight - b.$3 / 2 + dy,
      child: Container(
        width: b.$3,
        height: b.$3,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.4),
            colors: [Colors.white.withValues(alpha: 0.6), b.$4],
            stops: const [0.0, 0.5],
          ),
          color: b.$4.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

/// Shared gradient backdrop for menu screens.
class CandyBackground extends StatelessWidget {
  const CandyBackground({super.key, required this.child, this.bubbles = true});

  final Widget child;
  final bool bubbles;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: Stack(
        children: [
          if (bubbles) const Positioned.fill(child: FloatingBubbles()),
          Positioned.fill(child: SafeArea(child: child)),
        ],
      ),
    );
  }
}
