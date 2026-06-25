import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design system for Arrow Escape.
///
/// Calming, modern, rounded UI with a finger-friendly layout. All colors,
/// spacing and text styles live here so screens stay consistent.
class AppColors {
  AppColors._();

  // Brand / background
  static const Color background = Color(0xFF14182B);
  static const Color surface = Color(0xFF1E2440);
  static const Color surfaceAlt = Color(0xFF272E52);
  static const Color overlay = Color(0xCC0B0E1C);

  // Accents
  static const Color primary = Color(0xFF5B8DEF);
  static const Color primaryDark = Color(0xFF3C6BD4);
  static const Color secondary = Color(0xFF8A6BF2);
  static const Color success = Color(0xFF3FD3A1);
  static const Color warning = Color(0xFFF6C453);
  static const Color danger = Color(0xFFF06B6B);
  static const Color coin = Color(0xFFFFD45E);

  // Text
  static const Color textPrimary = Color(0xFFF4F6FF);
  static const Color textSecondary = Color(0xFFAEB6D8);
  static const Color textMuted = Color(0xFF6E76A0);

  // Arrow palette (color index -> color). 0 is the default neutral arrow.
  static const List<Color> arrowColors = <Color>[
    Color(0xFF5B8DEF), // 0 default blue
    Color(0xFFF06B6B), // 1 red
    Color(0xFF3FD3A1), // 2 green
    Color(0xFFF6C453), // 3 amber
    Color(0xFF8A6BF2), // 4 purple
    Color(0xFFEF8ACA), // 5 pink
  ];

  static Color arrowColor(int index) => arrowColors[index % arrowColors.length];
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const double radius = 18;
  static const double radiusLg = 28;
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    // Nunito — rounded, friendly and very readable; a great fit for a calm
    // casual puzzle game. Applied to the whole text theme so every screen
    // (and explicitly-styled Text that omits a family) inherits it.
    final textTheme = GoogleFonts.nunitoTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      textTheme: textTheme,
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      splashColor: AppColors.primary.withValues(alpha: 0.15),
      highlightColor: Colors.transparent,
    );
  }

  /// Standard rounded card decoration used across screens.
  static BoxDecoration card({Color? color, double radius = AppSpacing.radius}) {
    return BoxDecoration(
      color: color ?? AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  /// Subtle gradient for the main background.
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1B2142), AppColors.background],
  );
}
