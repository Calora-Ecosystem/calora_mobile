import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class WeightProgressChart extends StatelessWidget {
  final double startValue;
  final double endValue;
  final Color color;
  final double height;

  const WeightProgressChart({
    super.key,
    required this.startValue,
    required this.endValue,
    this.color = const Color(0xFF6BCF8E),
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _WeightChartPainter(
          startValue: startValue,
          endValue: endValue,
          color: color,
        ),
      ),
    );
  }
}

class _WeightChartPainter extends CustomPainter {
  final double startValue;
  final double endValue;
  final Color color;

  _WeightChartPainter({
    required this.startValue,
    required this.endValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 24.0;
    const rightPad = 24.0;
    const topPad = 18.0;
    const bottomPad = 18.0;

    final plotW = size.width - leftPad - rightPad;
    final plotH = size.height - topPad - bottomPad;

    final x1 = leftPad;
    final x2 = leftPad + plotW;

    final minV = math.min(startValue, endValue);
    final maxV = math.max(startValue, endValue);
    final range = (maxV - minV).abs();

    double yFor(double v) {
      if (range < 1e-9) {
        return topPad + plotH * 0.5;
      }
      final n = (v - minV) / range; // 0..1
      return topPad + (1 - n) * plotH;
    }

    final start = Offset(x1, yFor(startValue));
    final end = Offset(x2, yFor(endValue));

    final c1 = Offset(x1 + plotW * 0.35, start.dy);
    final c2 = Offset(x1 + plotW * 0.65, end.dy);

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);

    // Gradient fill
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.35),
          color.withValues(alpha: 0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final fillPath = Path.from(path)
      ..lineTo(end.dx, size.height)
      ..lineTo(start.dx, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    // Dots — the A/B cards above the chart already carry the numbers, so the
    // curve stays clean with just its start/end markers.
    _drawDot(canvas, start);
    _drawDot(canvas, end);
  }

  void _drawDot(Canvas canvas, Offset center) {
    final outer = Paint()..color = color;
    final inner = Paint()..color = Colors.white;

    canvas.drawCircle(center, 8, outer);
    canvas.drawCircle(center, 4, inner);
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter old) {
    return old.startValue != startValue || old.endValue != endValue || old.color != color;
  }
}
