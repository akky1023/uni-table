import 'dart:math';
import 'package:flutter/material.dart';

/// Geometry rather than font glyphs, so the marks are identical on every device.
class StatusMark extends StatelessWidget {
  final int shape;
  final bool filled, centerDot;
  final double size;
  final Color color;
  final String label;
  const StatusMark(
      {super.key,
      this.shape = 0,
      this.filled = true,
      this.centerDot = false,
      this.size = 12,
      this.color = const Color(0xff273b31),
      required this.label});
  @override
  Widget build(BuildContext context) => Semantics(
      label: label,
      child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
              painter: MarkPainter(shape, filled, centerDot, color))));
}

class MarkPainter extends CustomPainter {
  final int shape;
  final bool filled, centerDot;
  final Color color;
  const MarkPainter(this.shape, this.filled, this.centerDot, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2 - 1;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.3
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    if (shape == 9) {
      paint.style = PaintingStyle.stroke;
      canvas.drawLine(c + Offset(-r, -r), c + Offset(r, r), paint);
      canvas.drawLine(c + Offset(r, -r), c + Offset(-r, r), paint);
    } else if (shape == 10) {
      paint.style = PaintingStyle.stroke;
      canvas.drawLine(c + Offset(-r, 0), c + Offset(r, 0), paint);
      canvas.drawLine(c + Offset(0, -r), c + Offset(0, r), paint);
    } else if (shape == 0) {
      canvas.drawCircle(c, r * .75, paint);
    } else {
      final path = Path();
      if (shape == 8) {
        path.moveTo(c.dx, c.dy + r);
        path.cubicTo(c.dx - r * 2, c.dy - r * .2, c.dx - r, c.dy - r * 1.5,
            c.dx, c.dy - r * .4);
        path.cubicTo(c.dx + r, c.dy - r * 1.5, c.dx + r * 2, c.dy - r * .2,
            c.dx, c.dy + r);
      } else if (shape == 7) {
        path.moveTo(c.dx - r, c.dy - r);
        path.lineTo(c.dx + r, c.dy - r);
        path.lineTo(c.dx - r, c.dy + r);
        path.lineTo(c.dx + r, c.dy + r);
      } else {
        final sides =
            switch (shape) { 1 || 3 => 4, 2 => 3, 4 => 5, 5 => 6, _ => 10 };
        final start = shape == 1 ? pi / 4 : -pi / 2;
        for (var i = 0; i < sides; i++) {
          final radius = shape == 6 && i.isOdd ? r * .45 : r;
          final point = c +
              Offset(cos(start + 2 * pi * i / sides),
                      sin(start + 2 * pi * i / sides)) *
                  radius;
          if (i == 0) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }
    if (centerDot) canvas.drawCircle(c, r * .23, Paint()..color = color);
  }

  @override
  bool shouldRepaint(MarkPainter old) =>
      old.shape != shape ||
      old.filled != filled ||
      old.centerDot != centerDot ||
      old.color != color;
}
