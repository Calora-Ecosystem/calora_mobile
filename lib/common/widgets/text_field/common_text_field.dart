import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CommonTextField extends StatefulWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final Widget? prefix;
  final Widget? suffixIcon;
  final Widget? suffix;
  final EdgeInsets? contentPadding;

  const CommonTextField({
    super.key,
    required this.hint,
    this.onChanged,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.obscureText = false,
    this.prefix,
    this.suffixIcon,
    this.suffix,
    this.contentPadding,
  });

  @override
  State<CommonTextField> createState() => _CommonTextFieldState();
}

class _CommonTextFieldState extends State<CommonTextField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      onTapOutside: (_) => FocusManager.instance.primaryFocus!.unfocus(),
      controller: widget.controller,
      focusNode: _focusNode,
      onChanged: widget.onChanged,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: TextStyle(
          color: context.colors.textSub,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 0.8,
          leadingDistribution: TextLeadingDistribution.even,
        ),
        contentPadding: widget.contentPadding ?? const EdgeInsets.symmetric(horizontal: 16),
        suffix: widget.suffix,
        prefixIcon: widget.prefix,
        suffixIcon: widget.suffixIcon,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.colors.strokeSoft, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.colors.blue, width: 1.5),
        ),
      ),
    );
  }
}
