import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class DefaultBottomSheet extends StatelessWidget {
  final Color? color;
  final double radius;
  final EdgeInsets? padding;
  final EdgeInsets titlePadding;
  final Widget child;
  final bool showHandle;
  final double? height;
  final String? title;

  const DefaultBottomSheet({
    super.key,
    this.color,
    this.radius = 24,
    this.padding,
    required this.child,
    this.height,
    this.showHandle = true,
    this.title,
    this.titlePadding = const EdgeInsets.symmetric(horizontal: 20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(20).copyWith(top: 0, bottom: MediaQuery.viewPaddingOf(context).bottom + 14),
      decoration: BoxDecoration(
        color: color ?? context.colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHandle) ...[
            const SizedBox(height: 8),
            Align(
              child: Container(
                width: 24,
                height: 3,
                decoration: BoxDecoration(color: context.colors.strokeSub, borderRadius: BorderRadius.circular(100)),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (title != null) ...[
            Padding(
              padding: padding == EdgeInsets.zero ? titlePadding : EdgeInsets.zero,
              child: title
                  .text(16, 20, 600)
                  .c(context.colors.textPrimary)
                  .copyWith(maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(height: 16),
          ],
          Flexible(child: child),
        ],
      ),
    );
  }
}
