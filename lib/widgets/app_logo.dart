import 'package:flutter/material.dart';

import '../core/theme.dart';

/// The Arrow Escape brand logo: a glossy candy tile with a bold arrow breaking
/// out of it (escaping) plus a little motion trail and sparkles. Drawn with a
/// painter so it stays crisp at any size and matches the in-game tiles.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 104});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LogoPainter()),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;

    // Soft glow halo behind everything.
    canvas.drawCircle(
      Offset(s * 0.5, s * 0.54),
      s * 0.48,
      Paint()
        ..color = AppColors.secondary.withValues(alpha: 0.25)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.08),
    );

    // --- Candy tile -------------------------------------------------------
    final tile = Rect.fromLTWH(s * 0.16, s * 0.22, s * 0.56, s * 0.56);
    final radius = Radius.circular(s * 0.20);
    final tileRRect = RRect.fromRectAndRadius(tile, radius);

    // 3D base.
    canvas.drawRRect(
      tileRRect.shift(Offset(0, s * 0.055)),
      Paint()..color = AppColors.primaryDark,
    );
    // Glossy face.
    canvas.drawRRect(
      tileRRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6E97FF), AppColors.primary, Color(0xFF7B5BE0)],
        ).createShader(tile),
    );
    // Top shine.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          tile.left + s * 0.05,
          tile.top + s * 0.04,
          tile.width - s * 0.10,
          tile.height * 0.32,
        ),
        Radius.circular(s * 0.12),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.28),
    );

    // --- Escaping arrow (diagonal, up-right) ------------------------------
    final tail = Offset(s * 0.33, s * 0.70);
    final head = Offset(s * 0.86, s * 0.16);
    final dir = (head - tail);
    final len = dir.distance;
    final unit = dir / len;
    // Perpendicular for the arrow head wings.
    final perp = Offset(-unit.dy, unit.dx);
    final wing = s * 0.13;
    final back = head - unit * (s * 0.16);

    Path arrowPath() => Path()
      ..moveTo(tail.dx, tail.dy)
      ..lineTo(head.dx, head.dy)
      ..moveTo(head.dx, head.dy)
      ..lineTo(back.dx + perp.dx * wing, back.dy + perp.dy * wing)
      ..moveTo(head.dx, head.dy)
      ..lineTo(back.dx - perp.dx * wing, back.dy - perp.dy * wing);

    // Shadow.
    canvas.save();
    canvas.translate(0, s * 0.02);
    canvas.drawPath(
      arrowPath(),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.11
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
    // White arrow.
    canvas.drawPath(
      arrowPath(),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.11
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // --- Motion trail behind the tail -------------------------------------
    final trailPaint = Paint()
      ..color = AppColors.warning
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.05
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i <= 2; i++) {
      final o = -unit * (s * 0.08 * i) + Offset(s * 0.03, s * 0.04);
      canvas.drawLine(
        tail + o - unit * (s * 0.05),
        tail + o - unit * (s * 0.12),
        trailPaint..color = AppColors.warning.withValues(alpha: 0.9 - i * 0.3),
      );
    }

    // --- Sparkles ---------------------------------------------------------
    _sparkle(canvas, Offset(s * 0.80, s * 0.66), s * 0.05, AppColors.coin);
    _sparkle(canvas, Offset(s * 0.24, s * 0.20), s * 0.035, Colors.white);
  }

  void _sparkle(Canvas canvas, Offset c, double r, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c + Offset(0, -r), c + Offset(0, r), paint);
    canvas.drawLine(c + Offset(-r, 0), c + Offset(r, 0), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
