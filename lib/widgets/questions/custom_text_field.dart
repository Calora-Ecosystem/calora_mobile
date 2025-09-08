import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final String? hintText;
  final TextInputType? keyboardType;
  final Function(String) onChanged;

  const CustomTextField({super.key, this.hintText, this.keyboardType, required this.onChanged});

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TextField(
      controller: _controller,
      keyboardType: widget.keyboardType ?? TextInputType.text,
      textAlign: TextAlign.center,
      onChanged: (value) {
        widget.onChanged?.call(value.trim());
      },
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(
          color: colors.textStrong,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.2,
        ),
        filled: true,
        fillColor: colors.commonBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      ),
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.2),
      cursorColor: colors.textStrong,
    );
  }
}
