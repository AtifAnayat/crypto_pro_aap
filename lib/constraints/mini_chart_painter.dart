import 'dart:math' as math;

import 'package:flutter/material.dart';

class MiniChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  const MiniChartPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    final double minPrice = data.reduce(math.min);
    final double maxPrice = data.reduce(math.max);
    final double priceRange = maxPrice - minPrice;

    if (priceRange == 0) return;

    final double widthStep = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final double normalizedPrice = (data[i] - minPrice) / priceRange;
      final double x = i * widthStep;
      final double y = size.height * (1 - normalizedPrice);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant MiniChartPainter oldDelegate) =>
      data != oldDelegate.data;
}
