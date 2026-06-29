import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// A reusable Liquid-Glass surface: a refractive backdrop blur, a diagonal
/// sheen, a bright specular highlight skimming the top edge, a thin glass rim
/// and a soft float shadow.
///
/// Set [blur] to 0 to skip the (relatively expensive) [BackdropFilter] — useful
/// when many instances are on screen at once (e.g. list/grid items); the
/// translucent fill + sheen still reads as glass.
class LiquidGlass extends StatelessWidget {
  const LiquidGlass({
    super.key,
    required this.child,
    this.radius = 20,
    this.padding = EdgeInsets.zero,
    this.blur = 16,
    this.opacity = 0.55,
    this.tint,
    this.shadow = true,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double blur;

  /// Base white (or [tint]) alpha for the glass fill.
  final double opacity;

  /// Optional colour wash (e.g. a pink primary action) instead of clear glass.
  final Color? tint;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    final base = tint ?? Colors.white;

    final surface = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            base.withValues(alpha: (opacity + 0.08).clamp(0.0, 1.0)),
            base.withValues(alpha: (opacity - 0.22).clamp(0.0, 1.0)),
            base.withValues(alpha: (opacity - 0.06).clamp(0.0, 1.0)),
          ],
          stops: const [0, 0.55, 1],
        ),
        borderRadius: br,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.62),
          width: 1.2,
        ),
      ),
      child: Stack(
        children: [
          // Bright specular highlight along the top edge.
          Positioned(
            top: 0,
            left: radius * 0.4,
            right: radius * 0.4,
            child: IgnorePointer(
              child: Container(
                height: 7,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.7),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );

    Widget clipped = ClipRRect(borderRadius: br, child: surface);
    if (blur > 0) {
      clipped = ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: surface,
        ),
      );
    }

    if (!shadow) return clipped;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      ),
      child: clipped,
    );
  }
}
