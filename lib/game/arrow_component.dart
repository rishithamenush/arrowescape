import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/arrow.dart';

/// A single arrow rendered by Flame. Draws a rounded, gradient tile with a
/// bold directional arrow, handles taps, and exposes juicy escape / shake /
/// hint effects.
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

  Color get _color => AppColors.arrowColor(arrow.color);

  double get _angle => switch (arrow.dir) {
    ArrowDir.up => 0,
    ArrowDir.right => math.pi / 2,
    ArrowDir.down => math.pi,
    ArrowDir.left => -math.pi / 2,
  };

  @override
  void onTapDown(TapDownEvent event) => onTapArrow(this);

  @override
  void update(double dt) {
    super.update(dt);
    // Ease the glow towards its target so the hint pulse is smooth.
    final target = _highlighted ? 1.0 : 0.0;
    _glow += (target - _glow) * (dt * 8).clamp(0, 1);
  }

  @override
  void render(Canvas canvas) {
    final s = size.x;
    final rect = Rect.fromLTWH(0, 0, s, s);
    final radius = Radius.circular(s * 0.24);
    final rrect = RRect.fromRectAndRadius(rect, radius);

    // Drop shadow.
    canvas.drawRRect(
      rrect.shift(const Offset(0, 4)),
      Paint()
        ..color = _color.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Gradient body.
    final body = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          _color.withValues(alpha: 0.95),
          _color.withValues(alpha: 0.70),
        ],
      ).createShader(rect);
    canvas.drawRRect(rrect, body);

    // Border (brightens with the hint glow).
    canvas.drawRRect(
      rrect.deflate(0.75),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 + _glow * 2
        ..color = Color.lerp(Colors.white24, AppColors.warning, _glow)!,
    );

    // Hint glow halo.
    if (_glow > 0.01) {
      canvas.drawRRect(
        rrect.inflate(2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = AppColors.warning.withValues(alpha: 0.6 * _glow)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * _glow),
      );
    }

    // Arrow glyph, rotated to its direction.
    canvas.save();
    canvas.translate(s / 2, s / 2);
    canvas.rotate(_angle);
    _drawArrow(canvas, s);
    canvas.restore();
  }

  void _drawArrow(Canvas canvas, double s) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final half = s * 0.24;
    final head = s * 0.18;

    // Shaft.
    canvas.drawLine(Offset(0, half), Offset(0, -half), paint);
    // Arrow head.
    canvas.drawLine(Offset(0, -half), Offset(-head, -half + head), paint);
    canvas.drawLine(Offset(0, -half), Offset(head, -half + head), paint);
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
