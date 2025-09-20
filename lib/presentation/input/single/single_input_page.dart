import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer; // Import for log function

class SingleInputPage extends StatefulWidget {
  final String title;
  final TextInputType? textInputType;
  final String message;
  final String metrics;
  final Function(String) onSave;

  const SingleInputPage({
    super.key,
    required this.title,
    this.textInputType,
    this.metrics = "",
    required this.message,
    required this.onSave,
  });

  @override
  State<SingleInputPage> createState() => _SingleInputPageState();
}

class _SingleInputPageState extends State<SingleInputPage> {
  late TextEditingController controller;
  String currentText = '';
  bool isUserEditing = false;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();

    // Set initial text based on message and metrics
    if (widget.message.isNotEmpty) {
      currentText = widget.metrics.isNotEmpty
          ? "${widget.message} ${widget.metrics}"
          : widget.message;
    }

    controller.text = currentText;

    // Add listener to handle metrics automatically
    controller.addListener(_handleTextChange);
  }

  @override
  void dispose() {
    controller.removeListener(_handleTextChange);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              height: 2,
              width: 24,
              color: context.colors.strokeSub,
            ),
          ),
          const SizedBox(height: 8),
          widget.title.text(20, 24, 700).c(context.colors.textStrong),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: widget.textInputType ?? TextInputType.number,
            textAlign: TextAlign.center,
            onTap: () {
              // Set flag when user starts editing
              isUserEditing = true;

              // Move cursor to before metrics if user taps on the field
              if (widget.metrics.isNotEmpty &&
                  controller.text.endsWith(widget.metrics)) {
                final position = controller.text.length - widget.metrics.length;
                controller.selection = TextSelection.collapsed(
                  offset: position,
                );
              }
            },
            onEditingComplete: () {
              isUserEditing = false;
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: context.colors.backgroundElevation,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              hintStyle: TextStyle(color: context.colors.textPrimary),
            ),
          ),
          const SizedBox(height: 50),
          GestureDetector(
            onTap: () {
              // Remove metrics before saving if they exist
              String textToSave = controller.text;
              if (widget.metrics.isNotEmpty &&
                  textToSave.endsWith(widget.metrics)) {
                textToSave = textToSave
                    .substring(0, textToSave.length - widget.metrics.length)
                    .trim();
              }
              widget.onSave(textToSave);
            },
            child: Container(
              decoration: BoxDecoration(
                color: context.colors.accentSub,
                borderRadius: BorderRadius.circular(12),
              ),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Strings.save
                  .text(16, 20, 500)
                  .c(context.colors.white)
                  .copyWith(textAlign: TextAlign.center),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _handleTextChange() {
    if (widget.metrics.isEmpty || !isUserEditing) return;

    final currentValue = controller.text;
    final selection = controller.selection;

    // If user is deleting the metrics, don't interfere
    if (selection.base.offset < currentValue.length - widget.metrics.length) {
      return;
    }

    // Filter out non-numeric characters (except decimal point)
    String numericValue = currentValue.replaceAll(RegExp(r'[^0-9.]'), '');

    // Ensure only one decimal point
    if (numericValue.split('.').length > 2) {
      final parts = numericValue.split('.');
      numericValue = '${parts[0]}.${parts.sublist(1).join()}';
    }

    // If metrics is missing, add it back
    if (!currentValue.endsWith(widget.metrics)) {
      // Check if user is trying to completely delete the text
      if (currentValue.isEmpty) {
        return;
      }


      // Add metrics to the end of the numeric value
      final newValue = '$numericValue ${widget.metrics}';
      controller.value = TextEditingValue(
        text: newValue,
        selection: TextSelection.collapsed(
          offset: numericValue.length,
        ),
      );
    } else if (currentValue != '$numericValue ${widget.metrics}') {
      // Update the value if it contains non-numeric characters
      final newValue = '$numericValue ${widget.metrics}';
      controller.value = TextEditingValue(
        text: newValue,
        selection: TextSelection.collapsed(
          offset: numericValue.length,
        ),
      );
    }
  }
}
