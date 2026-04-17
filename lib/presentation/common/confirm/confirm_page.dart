import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ConfirmPage extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final String title;
  final String confirmText;
  final String cancelText;
  final Color? backgroundColor;
  final Color? iconBackgroundColor;
  final Color? iconColor;
  final Color? cancelBackgroundColor;
  final Color? cancelTextColor;
  final Color? confirmBackgroundColor;
  final Color? confirmTextColor;
  final Color? titleColor;
  final bool loading;

  const ConfirmPage({
    super.key,
    required this.onConfirm,
    required this.onCancel,
    required this.title,
    required this.confirmText,
    required this.cancelText,
    this.backgroundColor,
    this.iconBackgroundColor,
    this.iconColor,
    this.cancelBackgroundColor,
    this.cancelTextColor,
    this.confirmBackgroundColor,
    this.confirmTextColor,
    this.titleColor,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Dialog(
      backgroundColor: backgroundColor ?? colors.textWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBackgroundColor ?? colors.warningLighter,
                shape: BoxShape.circle,
              ),
              child: Assets.icons.warning.svg(
                colorFilter: ColorFilter.mode(
                  iconColor ?? colors.warningBase,
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(height: 8),
            title
                .text(16, 20, 400)
                .c(titleColor ?? colors.textStrong)
                .copyWith(textAlign: TextAlign.center),
            const SizedBox(height: 16),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: onCancel,
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        decoration: BoxDecoration(
                          color: cancelBackgroundColor ?? colors.errorLighter,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: loading
                            ? const CupertinoActivityIndicator()
                            : cancelText
                                  .text(16, 20, 500)
                                  .c(cancelTextColor ?? colors.errorBase)
                                  .copyWith(textAlign: TextAlign.center),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: onConfirm,
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        decoration: BoxDecoration(
                          color: confirmBackgroundColor ?? colors.backgroundElevation,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: confirmText
                            .text(16, 20, 500)
                            .c(confirmTextColor ?? colors.textStrong)
                            .copyWith(textAlign: TextAlign.center),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
