import 'package:calora/common/extensions/metrics_extension.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

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
    this.metrics = '',
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

    if (widget.message.isNotEmpty) {
      currentText = widget.metrics.isNotEmpty
          ? '${widget.message} ${widget.metrics}'
          : widget.message;
    }

    controller.text = currentText;

    // Add listener to handle metrics automatically
    controller.addListener(
      () => controller.handleMetricsChange(metrics: widget.metrics, isUserEditing: isUserEditing),
    );
  }

  @override
  void dispose() {
    controller.removeListener(
      () => controller.handleMetricsChange(metrics: widget.metrics, isUserEditing: isUserEditing),
    );
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(height: 2, width: 24, color: context.colors.strokeSub)),
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
              if (widget.metrics.isNotEmpty && controller.text.endsWith(widget.metrics)) {
                final position = controller.text.length - widget.metrics.length;
                controller.selection = TextSelection.collapsed(offset: position);
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
              if (widget.metrics.isNotEmpty && textToSave.endsWith(widget.metrics)) {
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
}
