import 'package:flutter/material.dart';

class LotusFlowerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const LotusFlowerPainter({
    required this.color,
    this.strokeWidth = 1.6,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // 1. Center upright almond/lotus petal
    final centerPetal = Path();
    centerPetal.moveTo(cx, h * 0.16);
    centerPetal.cubicTo(cx + w * 0.16, h * 0.38, cx + w * 0.16, h * 0.65, cx, h * 0.80);
    centerPetal.cubicTo(cx - w * 0.16, h * 0.65, cx - w * 0.16, h * 0.38, cx, h * 0.16);
    canvas.drawPath(centerPetal, paint);

    // 2. Left petal: flares outwards and up, meeting center at bottom join
    final leftPetal = Path();
    leftPetal.moveTo(cx, h * 0.80);
    leftPetal.cubicTo(cx - w * 0.18, h * 0.82, cx - w * 0.46, h * 0.64, cx - w * 0.40, h * 0.38);
    leftPetal.cubicTo(cx - w * 0.28, h * 0.48, cx - w * 0.16, h * 0.66, cx, h * 0.80);
    canvas.drawPath(leftPetal, paint);

    // 3. Right petal: flares outwards and up symmetrically
    final rightPetal = Path();
    rightPetal.moveTo(cx, h * 0.80);
    rightPetal.cubicTo(cx + w * 0.18, h * 0.82, cx + w * 0.46, h * 0.64, cx + w * 0.40, h * 0.38);
    rightPetal.cubicTo(cx + w * 0.28, h * 0.48, cx + w * 0.16, h * 0.66, cx, h * 0.80);
    canvas.drawPath(rightPetal, paint);
  }

  @override
  bool shouldRepaint(covariant LotusFlowerPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}

class BarbellIconPainter extends CustomPainter {
  final Color color;

  const BarbellIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final cy = h / 2;

    // Horizontal bar
    paint.strokeWidth = 2.4;
    paint.style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w * 0.16, cy), Offset(w * 0.84, cy), paint);

    // Left outer plate
    paint.strokeWidth = 3.2;
    canvas.drawLine(Offset(w * 0.22, cy - h * 0.28), Offset(w * 0.22, cy + h * 0.28), paint);

    // Left inner plate
    paint.strokeWidth = 2.4;
    canvas.drawLine(Offset(w * 0.32, cy - h * 0.20), Offset(w * 0.32, cy + h * 0.20), paint);

    // Right inner plate
    canvas.drawLine(Offset(w * 0.68, cy - h * 0.20), Offset(w * 0.68, cy + h * 0.20), paint);

    // Right outer plate
    paint.strokeWidth = 3.2;
    canvas.drawLine(Offset(w * 0.78, cy - h * 0.28), Offset(w * 0.78, cy + h * 0.28), paint);
  }

  @override
  bool shouldRepaint(covariant BarbellIconPainter oldDelegate) => oldDelegate.color != color;
}

class FootprintIconPainter extends CustomPainter {
  final Color color;

  const FootprintIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-0.35); // tilt ~20 degrees

    final path = Path();
    // Top loop (toe area)
    path.moveTo(0, -h * 0.32);
    path.cubicTo(w * 0.20, -h * 0.32, w * 0.22, -h * 0.08, w * 0.08, 0);
    // Waist curve
    path.cubicTo(w * 0.04, h * 0.04, w * 0.22, h * 0.12, w * 0.20, h * 0.30);
    // Bottom heel curve
    path.cubicTo(w * 0.18, h * 0.38, -w * 0.18, h * 0.38, -w * 0.20, h * 0.30);
    // Waist curve back
    path.cubicTo(-w * 0.22, h * 0.12, -w * 0.04, h * 0.04, -w * 0.08, 0);
    // Top curve back
    path.cubicTo(-w * 0.22, -h * 0.08, -w * 0.20, -h * 0.32, 0, -h * 0.32);

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FootprintIconPainter oldDelegate) => oldDelegate.color != color;
}
