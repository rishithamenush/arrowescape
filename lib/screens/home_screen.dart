import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../state/game_state.dart';
import '../widgets/candy.dart';
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  // Boba — the app's main character, up top where there's space.
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
                  CandyButton(
                    gradient: const [AppColors.pinkLight, AppColors.pink],
                    shadow: AppColors.pinkShadow,
                    radius: 24,
                    depth: 7,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 56,
                      vertical: 16,
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LevelSelectScreen(),
                      ),
                    ),
                    child: const Text(
                      'Play',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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
          // Audio controls tucked into the bottom-right corner.
          SafeArea(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12, right: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _audioToggle(
                      on: state.musicOn,
                      onIcon: Icons.music_note_rounded,
                      offIcon: Icons.music_off_rounded,
                      label: 'Music',
                      onTap: state.toggleMusic,
                    ),
                    const SizedBox(width: 12),
                    _audioToggle(
                      on: state.soundOn,
                      onIcon: Icons.volume_up_rounded,
                      offIcon: Icons.volume_off_rounded,
                      label: 'Sound',
                      onTap: state.toggleSound,
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

  Widget _audioToggle({
    required bool on,
    required IconData onIcon,
    required IconData offIcon,
    required String label,
    required VoidCallback onTap,
  }) {
    final color = on ? AppColors.accent : AppColors.muted;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: on ? 0.95 : 0.7),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(on ? onIcon : offIcon, color: color, size: 19),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: on ? AppColors.body : AppColors.muted,
          ),
        ),
      ],
    );
  }
}
