import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/widgets/button/animated_detector.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Button extends StatelessWidget {
  const Button({
    super.key,
    this.text,
    this.textColor,
    this.child,
    this.onPressed,
    this.enabled = true,
    this.loading = false,
    this.type = ButtonType.primary,
    this.width = double.infinity,
    this.height = 48,
    this.radius = 8,
    this.padding = EdgeInsets.zero,
  });

  final String? text;
  final Color? textColor;
  final Widget? child;
  final Function()? onPressed;
  final bool enabled;
  final bool loading;
  final ButtonType type;
  final double width;
  final double height;
  final double radius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor;
    final Color foregroundColor;
    final BorderSide? borderSide;

    switch (type) {
      case ButtonType.primary:
        backgroundColor = enabled ? context.colors.accentSub : context.colors.accentSoft;
        foregroundColor = textColor ?? (enabled ? context.colors.white : context.colors.textSub);
        borderSide = BorderSide.none;
        break;
      case ButtonType.secondary:
        backgroundColor = enabled ? context.colors.backgroundElevation : context.colors.strokeSoft;
        foregroundColor = textColor ?? (enabled ? context.colors.textPrimary : context.colors.textSub);
        borderSide = BorderSide.none;
        break;
      case ButtonType.container:
        backgroundColor = enabled ? Colors.white : context.colors.softGray;
        foregroundColor = textColor ?? (enabled ? context.colors.textPrimary : context.colors.textSub);
        borderSide = BorderSide.none;
        break;
    }

    return AnimatedDetector(
      enabled: enabled && !loading,
      onTap: onPressed,
      child: Container(
        width: width,
        height: height,
        margin: padding,
        child: FilledButton(
          onPressed: null,
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(backgroundColor),
            padding: const WidgetStatePropertyAll(EdgeInsets.zero),
            foregroundColor: WidgetStatePropertyAll(foregroundColor),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
                side: borderSide,
              ),
            ),
          ),
          child: loading
              ? CupertinoActivityIndicator(color: foregroundColor)
              : child ??
                    text
                        .text(16, 24, 400)
                        .c(foregroundColor)
                        .copyWith(
                          style: const TextStyle(
                            leadingDistribution: TextLeadingDistribution.even,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
        ),
      ),
    );
  }
}

enum ButtonType { primary, secondary, container }
