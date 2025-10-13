import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class ShimmerChild extends StatelessWidget {
  final double height;
  final double? width;
  final double? radius;
  final Color? color;

  const ShimmerChild({super.key, this.height = 24, this.width = 100, this.radius, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: color ?? context.colors.white,
        borderRadius: BorderRadius.circular(radius ?? (height / 2)),
      ),
    );
  }
}
