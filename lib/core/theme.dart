import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Candy-arcade design tokens for Bubble Pop.
class AppColors {
  AppColors._();

  // App background gradient.
  static const List<Color> bg = [
    Color(0xFFFFE3F6),
    Color(0xFFFFE9E3),
    Color(0xFFE7ECFF),
    Color(0xFFDFF5FF),
  ];

  // Text.
  static const Color heading = Color(0xFF5A3A6E);
  static const Color body = Color(0xFF7A5A8E);
  static const Color muted = Color(0xFF9A86AB);
  static const Color label = Color(0xFFB07DA0);
  static const Color accent = Color(0xFFFF4D8D);
  static const Color accent2 = Color(0xFFFF5C97);

  // Candy button families: [light, dark(shadow)].
  static const Color pink = Color(0xFFFF4D97);
  static const Color pinkLight = Color(0xFFFF8FC4);
  static const Color pinkShadow = Color(0xFFD62F76);
  static const Color mint = Color(0xFF2FC7A6);
  static const Color mintLight = Color(0xFF7BE0C8);
  static const Color mintShadow = Color(0xFF1B9D80);
  static const Color softPink = Color(0xFFFFE7F1);
  static const Color softPinkShadow = Color(0xFFFFC9DE);
  static const Color lavender = Color(0xFFEFE9F5);
  static const Color lavenderShadow = Color(0xFFD8CEE4);
  static const Color amber = Color(0xFFFF9A3D);
  static const Color amberLight = Color(0xFFFFD76B);
  static const Color amberShadow = Color(0xFFD77A1E);

  // White surfaces.
  static const Color pill = Color(0xCCFFFFFF);
  static const Color barButton = Color(0xD0FFFFFF);
  static const Color pillShadow = Color(0x40AA78A0);

  // Level card gradients [top, bottom] + shadow.
  static const List<List<Color>> levelCards = [
    [Color(0xFFFF9EC1), Color(0xFFFF5C97)],
    [Color(0xFFFFD76B), Color(0xFFFF9A3D)],
    [Color(0xFF7FE0F0), Color(0xFF2FB6D6)],
    [Color(0xFF9BE8B5), Color(0xFF3DDC84)],
  ];
  static const List<Color> levelShadow = [
    Color(0xFFD62F76),
    Color(0xFFD77A1E),
    Color(0xFF1F8FB0),
    Color(0xFF1EA65C),
  ];
  static const List<Color> lockedCard = [Color(0xFFCDBCD8), Color(0xFFA892B8)];
  static const Color lockedShadow = Color(0xFF8C7699);
}

class AppSpacing {
  AppSpacing._();
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
}

class AppTheme {
  AppTheme._();

  static ThemeData get theme {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    final textTheme = GoogleFonts.fredokaTextTheme(
      base.textTheme,
    ).apply(bodyColor: AppColors.heading, displayColor: AppColors.heading);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg.first,
      textTheme: textTheme,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.accent,
        secondary: AppColors.mint,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: AppColors.bg,
    stops: [0, 0.3, 0.65, 1],
  );
}
