import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

enum ShimmerType { white, backgroundElevation }

class ShimmerWrapper extends StatelessWidget {
  final bool loading;
  final Widget child;
  final double height;
  final double? width;
  final double? radius;
  final Color? color;
  final EdgeInsets margin;
  final ShimmerType type;
  final Border? border;
  final Widget? shimmerChild;

  const ShimmerWrapper({
    super.key,
    required this.loading,
    required this.child,
    this.height = 24,
    this.width = 100,
    this.radius,
    this.color,
    this.margin = EdgeInsets.zero,
    this.type = ShimmerType.white,
    this.border,
    this.shimmerChild,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      final Color baseColor;
      final Color highlightColor;
      switch (type) {
        case ShimmerType.white:
          baseColor = color ?? context.colors.white;
          highlightColor = context.colors.strokeSoft;

          break;

        case ShimmerType.backgroundElevation:
          baseColor = color ?? context.colors.backgroundElevation;
          highlightColor = context.colors.white;
          break;
      }

      return Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        period: const Duration(milliseconds: 1000),
        enabled: loading,
        child:
            shimmerChild ??
            ShimmerChild(
              height: height,
              width: width,
              margin: margin,
              borderRadius: BorderRadius.circular(radius ?? (height / 2).clamp(0, 100)),
              border: border,
              color: baseColor,
            ),
      );
    }
    return child;
  }
}

class ShimmerChild extends StatelessWidget {
  final double height;
  final double? width;
  final double radius;
  final Color? color;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry? borderRadius;
  final BoxBorder? border;

  const ShimmerChild({
    super.key,
    required this.height,
    this.width,
    this.radius = 8.0,
    this.color,
    this.margin,
    this.borderRadius,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? context.colors.white,
        borderRadius: borderRadius ?? BorderRadius.circular(radius),
        border: border,
      ),
    );
  }
}
