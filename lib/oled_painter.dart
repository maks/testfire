import 'dart:ui';

import 'package:flutter/material.dart';

class OLEDPainter extends CustomPainter {
  final List<bool> bitmap;

  OLEDPainter(this.bitmap);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white
      ..strokeWidth = 1
      ..isAntiAlias = true;

    int x = 0;
    int y = 0;
    final List<Offset> points = [];
    for (x = 0; x < 128; ++x) {
      for (y = 0; y < 64; ++y) {
        if (bitmap[x + (y * 128)]) {
          points.add(Offset(x.toDouble(), y.toDouble()));
        }
      }
    }
    canvas.drawPoints(PointMode.points, points, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
