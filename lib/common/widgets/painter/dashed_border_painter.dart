import 'package:flutter/material.dart';

class DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    const radius = 16.0;
    const dashLength = 60.0;

    Path topLeftCorner = Path()
      ..moveTo(0, radius + dashLength)
      ..lineTo(0, radius)
      ..arcToPoint(const Offset(radius, 0), radius: const Radius.circular(radius))
      ..lineTo(radius + dashLength, 0);
    canvas.drawPath(topLeftCorner, paint);

    Path topRightCorner = Path()
      ..moveTo(size.width - radius - dashLength, 0)
      ..lineTo(size.width - radius, 0)
      ..arcToPoint(Offset(size.width, radius), radius: const Radius.circular(radius))
      ..lineTo(size.width, radius + dashLength);
    canvas.drawPath(topRightCorner, paint);

    Path bottomLeftCorner = Path()
      ..moveTo(0, size.height - radius - dashLength)
      ..lineTo(0, size.height - radius)
      ..arcToPoint(Offset(radius, size.height), radius: const Radius.circular(radius), clockwise: false)
      ..lineTo(radius + dashLength, size.height);
    canvas.drawPath(bottomLeftCorner, paint);

    Path bottomRightCorner = Path()
      ..moveTo(size.width - radius - dashLength, size.height)
      ..lineTo(size.width - radius, size.height)
      ..arcToPoint(Offset(size.width, size.height - radius), radius: const Radius.circular(radius), clockwise: false)
      ..lineTo(size.width, size.height - radius - dashLength);
    canvas.drawPath(bottomRightCorner, paint);

    final leftGap = (size.height - 2 * radius - 2 * dashLength - 2 * dashLength) / 3;
    canvas.drawLine(
      Offset(0, radius + dashLength + leftGap),
      Offset(0, radius + dashLength + leftGap + dashLength),
      paint,
    );
    canvas.drawLine(
      Offset(0, radius + dashLength + 2 * leftGap + dashLength),
      Offset(0, radius + dashLength + 2 * leftGap + 2 * dashLength),
      paint,
    );

    final rightGap = (size.height - 2 * radius - 2 * dashLength - 2 * dashLength) / 3;
    canvas.drawLine(
      Offset(size.width, radius + dashLength + rightGap),
      Offset(size.width, radius + dashLength + rightGap + dashLength),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, radius + dashLength + 2 * rightGap + dashLength),
      Offset(size.width, radius + dashLength + 2 * rightGap + 2 * dashLength),
      paint,
    );

    final topCenter = size.width / 2;
    canvas.drawLine(Offset(topCenter - dashLength / 2, 0), Offset(topCenter + dashLength / 2, 0), paint);

    final bottomCenter = size.width / 2;
    canvas.drawLine(
      Offset(bottomCenter - dashLength / 2, size.height),
      Offset(bottomCenter + dashLength / 2, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
