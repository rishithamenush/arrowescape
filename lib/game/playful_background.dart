import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';

/// A cheerful, always-moving Flame backdrop shared by every screen: a soft
/// gradient with colourful bubbles and a few twinkling stars drifting upward.
/// Pure decoration — it ignores input so the Flutter UI on top stays tappable.
class PlayfulBackgroundGame extends FlameGame {
  final math.Random _rng = math.Random();

  @override
  Color backgroundColor() => AppColors.bgTop;

  @override
  Future<void> onLoad() async {
    const count = 22;
    for (var i = 0; i < count; i++) {
      add(_floater(initial: true));
    }
  }

  Component _floater({required bool initial}) {
    final isStar = _rng.nextDouble() < 0.28;
    final color = AppColors.arrowColor(
      _rng.nextInt(AppColors.arrowColors.length),
    );
    final radius = 8 + _rng.nextDouble() * 26;
    final speed = 8 + _rng.nextDouble() * 22;
    final x = _rng.nextDouble() * (size.x == 0 ? 400 : size.x);
    final y = initial
        ? _rng.nextDouble() * (size.y == 0 ? 800 : size.y)
        : (size.y + radius * 2);
    return _Floater(
      color: color,
      radius: radius,
      speed: speed,
      isStar: isStar,
      seedPhase: _rng.nextDouble() * math.pi * 2,
    )..position = Vector2(x, y);
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRect(
      rect,
      Paint()..shader = AppTheme.backgroundGradient.createShader(rect),
    );
    super.render(canvas);
  }
}

class _Floater extends PositionComponent {
  _Floater({
    required this.color,
    required this.radius,
    required this.speed,
    required this.isStar,
    required this.seedPhase,
  }) {
    size = Vector2.all(radius * 2);
    anchor = Anchor.center;
  }

  final Color color;
  final double radius;
  final double speed;
  final bool isStar;
  double seedPhase;

  @override
  void update(double dt) {
    super.update(dt);
    final game = findGame();
    if (game == null) return;
    seedPhase += dt;
    position.y -= speed * dt;
    position.x += math.sin(seedPhase) * 0.4;
    // Wrap back to the bottom once it floats off the top.
    if (position.y < -radius * 2) {
      position.y = game.size.y + radius * 2;
      position.x = math.Random().nextDouble() * game.size.x;
    }
  }

  @override
  void render(Canvas canvas) {
    final c = Offset(radius, radius);
    final paint = Paint()..color = color.withValues(alpha: 0.22);
    if (isStar) {
      _drawStar(canvas, c, radius, paint);
    } else {
      canvas.drawCircle(c, radius, paint);
      // Soft highlight to give the bubble some depth.
      canvas.drawCircle(
        Offset(radius * 0.68, radius * 0.66),
        radius * 0.26,
        Paint()..color = Colors.white.withValues(alpha: 0.35),
      );
    }
  }

  void _drawStar(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    const points = 5;
    for (var i = 0; i < points * 2; i++) {
      final isOuter = i.isEven;
      final rad = isOuter ? r : r * 0.45;
      final angle = (math.pi / points) * i - math.pi / 2;
      final p = center + Offset(math.cos(angle) * rad, math.sin(angle) * rad);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }
}
