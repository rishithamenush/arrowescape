import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/arrow.dart';

/// A single arrow rendered by Flame as a chunky, glossy 3D "candy button".
///
/// Every arrow is vividly colour-coded by its direction, which makes the board
/// bright and rainbow-like and also helps young players read it at a glance.
class ArrowComponent extends PositionComponent with TapCallbacks {
  ArrowComponent({
    required this.arrow,
    required this.onTapArrow,
    required double cell,
    required Vector2 center,
  }) {
    anchor = Anchor.center;
    size = Vector2.all(cell);
    position = center;
  }

  final ArrowModel arrow;
  final void Function(ArrowComponent) onTapArrow;

  bool _highlighted = false;
  double _glow = 0; // animated 0..1 glow used for the hint pulse

  /// Bright, distinct colour per direction.
  static const Map<ArrowDir, Color> _dirColors = {
    ArrowDir.up: Color(0xFF3D7BFF), // blue
    ArrowDir.right: Color(0xFF15C98A), // green
    ArrowDir.down: Color(0xFFB45CFF), // purple
    ArrowDir.left: Color(0xFFFF8A3D), // orange
  };

  Color get _color => _dirColors[arrow.dir]!;

  Color get displayColor => _color;

  double get _angle => switch (arrow.dir) {
    ArrowDir.up => 0,
    ArrowDir.right => math.pi / 2,
    ArrowDir.down => math.pi,
    ArrowDir.left => -math.pi / 2,
  };

  Color _lighten(Color c, double t) => Color.lerp(c, Colors.white, t)!;
  Color _darken(Color c, double t) => Color.lerp(c, Colors.black, t)!;

  @override
  void onTapDown(TapDownEvent event) => onTapArrow(this);

  @override
  void update(double dt) {
    super.update(dt);
    final target = _highlighted ? 1.0 : 0.0;
    _glow += (target - _glow) * (dt * 8).clamp(0, 1);
  }

  @override
  void render(Canvas canvas) {
    final s = size.x;
    final color = _color;
    final radius = Radius.circular(s * 0.28);
    final faceRect = Rect.fromLTWH(0, 0, s, s);
    final faceRRect = RRect.fromRectAndRadius(faceRect, radius);
    final depth = s * 0.12;

    // 1. Coloured glow / drop shadow.
    canvas.drawRRect(
      faceRRect.shift(Offset(0, depth * 0.9)),
      Paint()
        ..color = color.withValues(alpha: _highlighted ? 0.7 : 0.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, _glow > 0.1 ? 14 : 9),
    );

    // 2. Darker "side" below the face for a 3D button thickness.
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, depth, s, s), radius),
      Paint()..color = _darken(color, 0.28),
    );

    // 3. Glossy gradient face.
    canvas.drawRRect(
      faceRRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_lighten(color, 0.22), color, _darken(color, 0.08)],
          stops: const [0, 0.55, 1],
        ).createShader(faceRect),
    );

    // 4. Top gloss highlight.
    final gloss = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.12, s * 0.09, s * 0.76, s * 0.32),
      Radius.circular(s * 0.18),
    );
    canvas.drawRRect(
      gloss,
      Paint()..color = Colors.white.withValues(alpha: 0.26),
    );

    // 5. Rim + hint glow.
    canvas.drawRRect(
      faceRRect.deflate(0.8),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 + _glow * 2.5
        ..color = Color.lerp(
          Colors.white.withValues(alpha: 0.5),
          AppColors.warning,
          _glow,
        )!,
    );
    if (_glow > 0.01) {
      canvas.drawRRect(
        faceRRect.inflate(2.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = AppColors.warning.withValues(alpha: 0.7 * _glow)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 7 * _glow),
      );
    }

    // 6. Bold arrow glyph (with a soft shadow), rotated to its direction.
    canvas.save();
    canvas.translate(s / 2, s / 2);
    canvas.rotate(_angle);
    _drawArrow(canvas, s);
    canvas.restore();
  }

  void _drawArrow(Canvas canvas, double s) {
    final half = s * 0.23;
    final head = s * 0.19;

    Path arrowPath() {
      return Path()
        ..moveTo(0, half)
        ..lineTo(0, -half)
        ..moveTo(0, -half)
        ..lineTo(-head, -half + head)
        ..moveTo(0, -half)
        ..lineTo(head, -half + head);
    }

    // Drop shadow under the glyph for depth.
    canvas.save();
    canvas.translate(0, s * 0.035);
    canvas.drawPath(
      arrowPath(),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.15
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();

    // White glyph on top.
    canvas.drawPath(
      arrowPath(),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.15
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  /// Slides the arrow off the board while shrinking, then removes it and
  /// invokes [onDone] (used to re-check win / stuck after the animation).
  void playEscape(Vector2 offset, VoidCallback onDone) {
    add(
      MoveEffect.by(
        offset,
        EffectController(duration: 0.30, curve: Curves.easeIn),
      ),
    );
    add(
      ScaleEffect.to(
        Vector2.all(0.25),
        EffectController(duration: 0.30, curve: Curves.easeIn),
        onComplete: () {
          removeFromParent();
          onDone();
        },
      ),
    );
  }

  /// Quick horizontal shake when the arrow is blocked.
  void playShake(VoidCallback onDone) {
    add(
      MoveEffect.by(
        Vector2(9, 0),
        EffectController(
          duration: 0.05,
          alternate: true,
          repeatCount: 4,
          curve: Curves.easeInOut,
        ),
        onComplete: onDone,
      ),
    );
  }

  /// Pulses the hint glow for [duration].
  void pulseHint({Duration duration = const Duration(milliseconds: 1400)}) {
    _highlighted = true;
    add(
      ScaleEffect.by(
        Vector2.all(1.12),
        EffectController(
          duration: 0.35,
          alternate: true,
          repeatCount: 2,
          curve: Curves.easeInOut,
        ),
      ),
    );
    Future.delayed(duration, () {
      _highlighted = false;
    });
  }
}
