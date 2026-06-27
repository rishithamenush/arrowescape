import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'bubble_engine.dart';

/// Thin Flame wrapper that drives the [BubbleEngine] game loop and renders it.
/// Input (aim / shoot) is delivered from a Flutter [Listener] in the screen so
/// pointer coordinates map directly to the board.
class BubblePopGame extends FlameGame {
  BubblePopGame({required this.engine, required this.levelIndex});

  final BubbleEngine engine;
  final int levelIndex;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    engine.setSize(size.x, size.y);
    engine.boot(levelIndex);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded && size.x > 0 && size.y > 0) {
      engine.setSize(size.x, size.y);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    engine.update(math.min(dt, 0.033));
  }

  @override
  void render(Canvas canvas) {
    engine.render(canvas);
    super.render(canvas);
  }
}
