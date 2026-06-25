import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Shared gradient backdrop used by every screen for a consistent look.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child, this.safeArea = true});

  final Widget child;
  final bool safeArea;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: safeArea ? SafeArea(child: child) : child,
    );
  }
}
