import 'dart:math';

import 'package:flutter/material.dart';

class RoundedTrianglePainter extends CustomPainter {
  double distanceFactor = 0.2;

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.green[500]!
      ..style = PaintingStyle.fill;

    Point p1 = Point(size.width / 2, 0);
    Point p2 = Point(0, size.width);
    Point p3 = Point(size.width, size.width);

    Point p1p2Start = getLinePoint(p1, p2, closeToStart: true);
    Point p1p2End = getLinePoint(p1, p2, closeToStart: false);

    Point p2p3Start = getLinePoint(p2, p3, closeToStart: true);
    Point p2p3End = getLinePoint(p2, p3, closeToStart: false);

    Point p3p1Start = getLinePoint(p3, p1, closeToStart: true);
    Point p3p1End = getLinePoint(p3, p1, closeToStart: false);

    canvas.drawPath(
      Path()
        ..moveTo(
          p1p2Start.x.toDouble(),
          p1p2Start.y.toDouble(),
        )
        ..lineTo(
          p1p2End.x.toDouble(),
          p1p2End.y.toDouble(),
        )
        ..quadraticBezierTo(
          p2.x.toDouble(),
          p2.y.toDouble(),
          p2p3Start.x.toDouble(),
          p2p3Start.y.toDouble(),
        )
        ..lineTo(
          p2p3End.x.toDouble(),
          p2p3End.y.toDouble(),
        )
        ..quadraticBezierTo(
          p3.x.toDouble(),
          p3.y.toDouble(),
          p3p1Start.x.toDouble(),
          p3p1Start.y.toDouble(),
        )
        ..lineTo(
          p3p1End.x.toDouble(),
          p3p1End.y.toDouble(),
        )
        ..quadraticBezierTo(
          p1.x.toDouble(),
          p1.y.toDouble(),
          p1p2Start.x.toDouble(),
          p1p2Start.y.toDouble(),
        ),
      paint,
    );
  }

  Point getLinePoint(Point start, Point end, {required bool closeToStart}) {
    final double correctedDistanceFactor = closeToStart ? distanceFactor : (1 - distanceFactor);
    int x = (start.x * (1 - correctedDistanceFactor) + end.x * correctedDistanceFactor).round();
    int y = (start.y * (1 - correctedDistanceFactor) + end.y * correctedDistanceFactor).round();
    return Point(x, y);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
