import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../state/game_state.dart';
import 'level_select_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = GameScope.of(context);
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen home background.
          Positioned.fill(
            child: Image.asset('assets/boba/background.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Scale the hero block to the available height so it never
                  // overflows on short devices and never looks oversized on
                  // tall ones. Tuned around a ~660pt reference layout.
                  final h = constraints.maxHeight;
                  final w = constraints.maxWidth;
                  final s = (h / 660).clamp(0.72, 1.0);
                  final topGap = (h * 0.1).clamp(24.0, 80.0);
                  // Keep horizontal padding proportional but bounded so wide
                  // and narrow screens both stay comfortable.
                  final hPad = (w * 0.08).clamp(20.0, 32.0);

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: topGap),
                        // Boba — the app's main character.
                        Flexible(
                          child: Image.asset(
                            'assets/boba/chara1.png',
                            height: 210 * s,
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(height: 14 * s),
                        Text(
                          'SWEET',
                          style: TextStyle(
                            fontSize: 18 * s,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 6,
                            color: AppColors.accent2,
                          ),
                        ),
                        SizedBox(height: 6 * s),
                        ShaderMask(
                          shaderCallback: (rect) => const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFFFFD23F),
                              Color(0xFFFF7A9E),
                              Color(0xFFFF4D8D),
                            ],
                            stops: [0, 0.55, 1],
                          ).createShader(rect),
                          child: Text(
                            'Bubble\nPop',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 64 * s,
                              height: 0.92,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(height: 34 * s),
                        _glassPlayButton(
                          // Cap the button width so it fills narrow screens
                          // without overflowing and stays tidy on wide ones.
                          width: math.min(w - hPad * 2, 320.0),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LevelSelectScreen(),
                            ),
                          ),
                        ),
                        SizedBox(height: 18 * s),
                        const SizedBox(
                          width: 250,
                          child: Text(
                            'Drag to aim, release to shoot. Pop three or more of a color to clear them.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.heading,
                              height: 1.35,
                              shadows: [
                                Shadow(color: Colors.white, blurRadius: 6),
                                Shadow(color: Colors.white, blurRadius: 6),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          // Audio controls — two separate liquid-glass pills at bottom-center.
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _glassPill(
                      child: _glassToggle(
                        on: state.musicOn,
                        onIcon: Icons.music_note_rounded,
                        offIcon: Icons.music_off_rounded,
                        label: 'Music',
                        onTap: state.toggleMusic,
                      ),
                    ),
                    const SizedBox(width: 14),
                    _glassPill(
                      child: _glassToggle(
                        on: state.soundOn,
                        onIcon: Icons.volume_up_rounded,
                        offIcon: Icons.volume_off_rounded,
                        label: 'Sound',
                        onTap: state.toggleSound,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The primary "Play" call-to-action as a pink-tinted Liquid-Glass capsule.
  Widget _glassPlayButton({required VoidCallback onTap, required double width}) {
    final br = BorderRadius.circular(26);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: br,
          boxShadow: [
            BoxShadow(
              color: AppColors.pinkShadow.withValues(alpha: 0.5),
              blurRadius: 18,
              offset: const Offset(0, 9),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: -2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: br,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                // Pink-tinted refractive glass so it stays the hero action.
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.pinkLight.withValues(alpha: 0.85),
                    AppColors.pink.withValues(alpha: 0.72),
                  ],
                ),
                borderRadius: br,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.65),
                  width: 1.5,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Bright specular highlight along the top edge.
                  Positioned(
                    top: 0,
                    left: 14,
                    right: 14,
                    child: IgnorePointer(
                      child: Container(
                        height: 10,
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
                  const Text(
                    'Play',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      shadows: [
                        Shadow(color: Color(0x55000000), offset: Offset(0, 1)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }

  /// A single floating Liquid-Glass capsule wrapping one control.
  Widget _glassPill({required Widget child}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          // Soft drop shadow so the glass floats.
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
          // Faint outer glow (liquid-glass halo).
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.35),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              // Diagonal refractive sheen instead of a flat fill.
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.6),
                  Colors.white.withValues(alpha: 0.22),
                  Colors.white.withValues(alpha: 0.4),
                ],
                stops: const [0, 0.55, 1],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.7),
                width: 1.3,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Bright specular highlight skimming the top edge.
                Positioned(
                  top: 0,
                  left: 7,
                  right: 7,
                  child: IgnorePointer(
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.75),
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassToggle({
    required bool on,
    required IconData onIcon,
    required IconData offIcon,
    required String label,
    required VoidCallback onTap,
  }) {
    final color = on ? AppColors.accent : AppColors.muted;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(on ? onIcon : offIcon, size: 18, color: color),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: on ? AppColors.body : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
