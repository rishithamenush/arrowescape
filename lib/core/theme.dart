import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bright, playful design system tuned for kids — candy colors, big rounded
/// shapes, soft colored shadows and a friendly rounded font.
class AppColors {
  AppColors._();

  // Cheerful sky gradient used behind every screen.
  static const Color bgTop = Color(0xFF7CC8FF); // sky blue
  static const Color bgBottom = Color(0xFFC9A9FF); // soft purple

  // Card / surface
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF3F5FF);
  static const Color hairline = Color(0x141B1B3A);
  static const Color overlay = Color(0x802A1A66);

  // Accents (vivid + friendly)
  static const Color primary = Color(0xFF5B7CFA);
  static const Color primaryDark = Color(0xFF3F5BE0);
  static const Color secondary = Color(0xFFA45EFF);
  static const Color success = Color(0xFF22C77B);
  static const Color warning = Color(0xFFFFB020);
  static const Color danger = Color(0xFFFF5A7E);
  static const Color coin = Color(0xFFFFC93C);

  // Text (dark on light)
  static const Color textPrimary = Color(0xFF2B2D55);
  static const Color textSecondary = Color(0xFF6E7191);
  static const Color textMuted = Color(0xFFAEB0C8);
  static const Color onColor = Color(0xFFFFFFFF);

  /// Candy arrow palette. 0 is the default friendly blue.
  static const List<Color> arrowColors = <Color>[
    Color(0xFF54A0FF), // blue
    Color(0xFFFF6B6B), // red
    Color(0xFF1DD1A1), // green
    Color(0xFFFEC130), // yellow
    Color(0xFFA55EEA), // purple
    Color(0xFFFF6BCB), // pink
    Color(0xFFFF9F43), // orange
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

  static const double radius = 22;
  static const double radiusLg = 32;
}

class AppTheme {
  AppTheme._();

  static ThemeData get playful {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    // Baloo 2 — super rounded and playful; perfect for a children's game.
    final textTheme = GoogleFonts.baloo2TextTheme(base.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bgTop,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      textTheme: textTheme,
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      splashColor: AppColors.primary.withValues(alpha: 0.12),
      highlightColor: Colors.transparent,
    );
  }

  /// Soft, colored card with a playful drop shadow.
  static BoxDecoration card({
    Color? color,
    double radius = AppSpacing.radius,
    Color? glow,
  }) {
    final shadow = (glow ?? AppColors.primary).withValues(alpha: 0.18);
    return BoxDecoration(
      color: color ?? AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(color: shadow, blurRadius: 18, offset: const Offset(0, 8)),
      ],
    );
  }

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.bgTop, AppColors.bgBottom],
  );
}
