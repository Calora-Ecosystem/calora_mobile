import 'package:calora/common/extensions/build_context_extensions.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class BottomBox extends StatelessWidget {
  final EdgeInsets? padding;
  final double radius;
  final Widget child;
  final Color? color;
  const BottomBox({super.key, this.padding, this.radius = 0, required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.only(top: 8, left: 16, right: 16, bottom: context.bottomPadding + 8),
      decoration: BoxDecoration(
        color: color ?? context.colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
        border: Border(top: BorderSide(color: context.colors.strokeSoft)),
      ),
      child: child,
    );
  }
}
