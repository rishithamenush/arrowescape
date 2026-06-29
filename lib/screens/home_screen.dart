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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 80),
                    // Boba — the app's main character.
                    Image.asset(
                      'assets/boba/chara1.png',
                      height: 210,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'SWEET',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 6,
                        color: AppColors.accent2,
                      ),
                    ),
                    const SizedBox(height: 6),
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
                      child: const Text(
                        'Bubble\nPop',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 64,
                          height: 0.92,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Aim • Match 3 • Clear the board',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.body,
                      ),
                    ),
                    const SizedBox(height: 34),
                    _glassPlayButton(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LevelSelectScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const SizedBox(
                      width: 240,
                      child: Text(
                        'Drag to aim, release to shoot. Pop three or more of a color to clear them.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
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
  Widget _glassPlayButton({required VoidCallback onTap}) {
    final br = BorderRadius.circular(26);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
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
              padding: const EdgeInsets.symmetric(horizontal: 104, vertical: 16),
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
