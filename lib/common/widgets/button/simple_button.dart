import 'package:calora/common/extensions/text_extensions.dart';
import 'package:flutter/material.dart';

enum IconPosition { left, right }

class SimpleButton extends StatelessWidget {
  final String? text;
  final Widget? icon;
  final IconPosition iconPosition;
  final VoidCallback onPressed;
  final Color color;
  final Color textColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final MainAxisAlignment alignment;

  const SimpleButton({
    super.key,
    this.text,
    this.icon,
    this.iconPosition = IconPosition.left,
    required this.onPressed,
    required this.color,
    required this.textColor,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    this.alignment = MainAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(borderRadius)),
        child: Row(
          mainAxisAlignment: alignment,
          children: [
            if (icon != null && iconPosition == IconPosition.left) ...[
              icon!,
              if (text != null) const SizedBox(width: 8),
            ],

            // Text
            if (text != null)
              Flexible(
                child: text!.text(16, 20, 500).c(textColor).copyWith(textAlign: TextAlign.center),
              ),

            if (icon != null && iconPosition == IconPosition.right) ...[
              if (text != null) const SizedBox(width: 8),
              icon!,
            ],
          ],
        ),
      ),
    );
  }
}
