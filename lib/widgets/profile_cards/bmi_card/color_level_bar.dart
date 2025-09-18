import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class ColorIndicatorBar extends StatelessWidget {
  final double indicatorPosition;

  const ColorIndicatorBar({Key? key, required this.indicatorPosition}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Color> colors = [
      context.colors.informationBase,
      context.colors.accentSub,
      context.colors.awayBase,
      context.colors.warningBase,
      context.colors.errorBase,
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          children: [
            Align(
              alignment: Alignment((indicatorPosition * 2) - 1, 0),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 0),
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
