import 'package:calora/common/extensions/text_extensions.dart';
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
    this.type = Type.primary,
  });

  final String? text;
  final Color? textColor;
  final Widget? child;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool loading;
  final Type type;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor;
    final Color? borderColor;
    switch (type) {
      case Type.primary:
        backgroundColor = context.colors.accentSub;
        borderColor = null;
        break;
      case Type.secondary:
        backgroundColor = context.colors.backgroundBase;
        borderColor = context.colors.strokeSoft;
        break;
    }
    return Theme(
      data: ThemeData(
        filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.fromMap({
              WidgetState.disabled: Colors.grey,
              WidgetState.any: backgroundColor,
            }),
            padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: borderColor == null ? BorderSide.none : BorderSide(color: borderColor),
              ),
            ),
          ),
        ),
      ),
      child: FilledButton(
        onPressed: onPressed,
        child: loading
            ? CupertinoActivityIndicator(color: context.colors.textWhite)
            : text?.text(16, 20, 500).c(textColor ?? context.colors.textWhite) ?? child,
      ),
    );
  }
}

enum Type { primary, secondary }
