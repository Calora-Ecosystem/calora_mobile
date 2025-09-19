import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

Future<void> showInputBottomSheet({
  required BuildContext context,
  required String title,
  String? initialValue,
  required void Function(String value) onSave,
}) {
  final controller = TextEditingController(text: initialValue ?? "");

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colors.white,
    builder: (context) {
      return SafeArea(
        child: Container(
          margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(height: 2, width: 24, color: context.colors.strokeSoft)),
              title.text(20, 24, 700).c(context.colors.textStrong),
              const SizedBox(height: 13),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: context.colors.backgroundElevation,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 50),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  onSave(controller.text);
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
              SizedBox(height: 16),
            ],
          ),
        ),
      );
    },
  );
}
