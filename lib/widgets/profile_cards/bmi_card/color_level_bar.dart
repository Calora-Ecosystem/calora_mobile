import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class ColorIndicatorBar extends StatelessWidget {
  final double bmi;

  const ColorIndicatorBar({super.key, required this.bmi});

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = [
      context.colors.blue,
      context.colors.green,
      context.colors.yellow,
      context.colors.orange,
      context.colors.red,
      context.colors.darkRed,
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          children: [
            Align(
              alignment: Alignment((_calculateIndicatorPosition(bmi) * 2) - 1, 0),
              child: Padding(
                padding: const EdgeInsets.only(),
                child: CustomPaint(
                  painter: TrianglePainter(color: context.colors.iconSub, pointingUp: false),
                  child: SizedBox(width: 14, height: 7),
                ),
              ),
            ),
            Container(
              height: 20,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: colors.map((color) {
                  return Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.horizontal(
                          left: color == colors.first ? Radius.circular(20) : Radius.zero,
                          right: color == colors.last ? Radius.circular(20) : Radius.zero,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  double _calculateIndicatorPosition(double bmi) {
    if (bmi <= 0) return 0.0;
    if (bmi >= 40) return 1.0;
    return (bmi / 40).clamp(0.0, 1.0);
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;
  final bool pointingUp;

  TrianglePainter({required this.color, this.pointingUp = true});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    if (pointingUp) {
      path.moveTo(size.width / 2, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(size.width / 2, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
