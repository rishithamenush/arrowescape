import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/playful_background.dart';

/// Shared backdrop for every screen: a live Flame scene (gradient + floating
/// bubbles and stars) with the screen content layered on top.
///
/// The Flame game instance is held in state so it isn't recreated on rebuild.
class AppBackground extends StatefulWidget {
  const AppBackground({super.key, required this.child, this.safeArea = true});

  final Widget child;
  final bool safeArea;

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground> {
  late final PlayfulBackgroundGame _game = PlayfulBackgroundGame();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: GameWidget(game: _game)),
        Positioned.fill(
          child: widget.safeArea ? SafeArea(child: widget.child) : widget.child,
        ),
      ],
    );
  }
}
