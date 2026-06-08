import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CandleIcon extends StatelessWidget {
  final double size;
  final Color flameColor;

  const CandleIcon({
    super.key,
    this.size = 24,
    this.flameColor = AppColors.warmAmber,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Luminary candle',
      child: CustomPaint(
        size: Size(size * (24 / 36), size),
        painter: _CandlePainter(flameColor: flameColor),
      ),
    );
  }
}

class _CandlePainter extends CustomPainter {
  final Color flameColor;
  _CandlePainter({required this.flameColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Scale factors from 24x36 viewBox
    final sx = w / 24;
    final sy = h / 36;

    // Candle body (cream rect at bottom)
    final bodyPaint = Paint()..color = const Color(0xFFF5D5B5);
    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(8 * sx, 20 * sy, 8 * sx, 13 * sy),
      Radius.circular(2 * sx),
    );
    canvas.drawRRect(bodyRRect, bodyPaint);

    // Flame outer (warmAmber ellipse)
    final flameOuterPaint = Paint()
      ..color = flameColor.withAlpha(230);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(12 * sx, 14 * sy),
        width: 10 * sx,
        height: 16 * sy,
      ),
      flameOuterPaint,
    );

    // Flame inner (white at 60% opacity)
    final flameInnerPaint = Paint()
      ..color = Colors.white.withAlpha(153);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(12 * sx, 16 * sy),
        width: 6 * sx,
        height: 10 * sy,
      ),
      flameInnerPaint,
    );

    // Wick
    final wickPaint = Paint()
      ..color = const Color(0xFF555555)
      ..strokeWidth = 1.2 * sx
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(12 * sx, 20 * sy),
      Offset(12 * sx, 22 * sy),
      wickPaint,
    );
  }

  @override
  bool shouldRepaint(_CandlePainter old) => old.flameColor != flameColor;
}
