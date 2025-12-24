import 'package:calora/common/extensions/metrics_extension.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final String? hintText;
  final TextInputType? keyboardType;
  final Function(String) onChanged;
  final String metrics;

  const CustomTextField({
    super.key,
    this.hintText,
    this.keyboardType,
    required this.onChanged,
    this.metrics = '',
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late final TextEditingController _controller;
  bool isUserEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();

    _controller.addListener(
      () => _controller.handleMetricsChange(metrics: widget.metrics, isUserEditing: isUserEditing),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(
      () => _controller.handleMetricsChange(metrics: widget.metrics, isUserEditing: isUserEditing),
    );
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TextField(
      controller: _controller,
      keyboardType: widget.keyboardType ?? TextInputType.number,
      textAlign: TextAlign.center,
      onTap: () {
        isUserEditing = true;
        if (widget.metrics.isNotEmpty && _controller.text.endsWith(widget.metrics)) {
          final pos = _controller.text.length - widget.metrics.length;
          _controller.selection = TextSelection.collapsed(offset: pos);
        }
      },
      onEditingComplete: () {
        isUserEditing = false;
      },
      onChanged: (value) {
        String textToSend = value;
        if (widget.metrics.isNotEmpty && textToSend.endsWith(widget.metrics)) {
          textToSend = textToSend.substring(0, textToSend.length - widget.metrics.length).trim();
        }
        widget.onChanged(textToSend);
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
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 0.8),
      cursorColor: colors.textStrong,
    );
  }
}
