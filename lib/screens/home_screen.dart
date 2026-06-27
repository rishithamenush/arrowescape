import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../widgets/candy.dart';
import 'level_select_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CandyBackground(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                  MaterialPageRoute(builder: (_) => const LevelSelectScreen()),
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
            ],
          ),
        ),
      ),
    );
  }
}
