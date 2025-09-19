import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class SvgButton extends StatelessWidget {
  final Widget assetPath;
  final VoidCallback onTap;
  final bool isSelected;

  const SvgButton({
    super.key,
    required this.assetPath,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        height: 80,
        width: 80,
        decoration: BoxDecoration(
          color: context.colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.colors.strokeSoft, width: 0.8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              assetPath,
              if (isSelected) ...[
                Container(color: Color(0x6464644D)),
                Center(
                  child: Container(
                    height: 36,
                    width: 36,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.colors.accentSub,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Assets.icons.checkmarkCircle.svg(fit: BoxFit.fill),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
