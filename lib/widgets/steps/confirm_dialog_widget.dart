import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class ConfirmDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const ConfirmDialog({super.key, required this.onConfirm, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.colors.textWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colors.warningLighter,
                shape: BoxShape.circle,
              ),
              child: Assets.icons.warning.svg(),
            ),
            const SizedBox(height: 8),
            Strings.areYouSureDeleteStatistic
                .text(16, 20, 400)
                .c(context.colors.textStrong)
                .copyWith(textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      onCancel();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: context.colors.errorLighter,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Strings.cleaning
                          .text(16, 20, 500)
                          .c(context.colors.errorBase)
                          .copyWith(textAlign: TextAlign.center),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      onConfirm();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: context.colors.backgroundElevation,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Strings.rejection
                          .text(16, 20, 500)
                          .c(context.colors.textStrong)
                          .copyWith(textAlign: TextAlign.center),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
