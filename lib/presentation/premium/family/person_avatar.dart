import 'package:flutter/material.dart';

/// Neutral person silhouette in a circle — head and shoulders, no face.
/// The family plan's "you" and "your loved one" on the tariffs page and in
/// the code sheet.
class PersonAvatar extends StatelessWidget {
  final double size;
  final Color background;
  final Color foreground;

  const PersonAvatar({
    super.key,
    required this.size,
    required this.background,
    required this.foreground,
  });

  /// Warm tint for the second person, so the pair reads as two people.
  static const partnerBackground = Color(0xFFFCE9D2);
  static const partnerForeground = Color(0xFFD9822B);

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _AvatarPainter(background, foreground),
  );
}

class _AvatarPainter extends CustomPainter {
  final Color background;
  final Color foreground;

  const _AvatarPainter(this.background, this.foreground);

  @override
  void paint(Canvas canvas, Size size) {
    final d = size.width;
    final circle = Path()..addOval(Offset.zero & size);
    canvas.drawPath(circle, Paint()..color = background);

    canvas.save();
    canvas.clipPath(circle);
    final fill = Paint()..color = foreground;
    canvas.drawCircle(Offset(d * 0.5, d * 0.39), d * 0.17, fill);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(d * 0.5, d * 0.98),
        width: d * 0.66,
        height: d * 0.56,
      ),
      fill,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AvatarPainter old) =>
      old.background != background || old.foreground != foreground;
}
