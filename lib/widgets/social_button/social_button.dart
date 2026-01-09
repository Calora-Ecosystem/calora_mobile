import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class SocialButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Widget icon;
  final bool isSelected;

  const SocialButton({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSelected ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? context.colors.backgroundElevation
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? context.colors.strokeSoft
                : context.colors.backgroundElevation,
          ),
        ),
        child: Row(
          mainAxisAlignment: isSelected
              ? MainAxisAlignment.spaceBetween
              : MainAxisAlignment.center,
          children: [
            Row(
              children: [
                icon,
                const SizedBox(width: 12),
                label.text(14, 18, 500).c(context.colors.textStrong),
              ],
            ),
            if (isSelected) Assets.icons.doneIcon.svg(),
          ],
        ),
      ),
    );
  }
}
