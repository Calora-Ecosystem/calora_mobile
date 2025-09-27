import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class NavigationButtons extends StatelessWidget {
  final int currentIndex;
  final int total;
  final bool isAnswerProvided;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onFinish;

  const NavigationButtons({
    super.key,
    required this.currentIndex,
    required this.total,
    required this.isAnswerProvided,
    required this.onNext,
    required this.onBack,
    required this.onFinish,
  });

  bool get isLast => currentIndex == total - 1;
  bool get hasPrevious => currentIndex > 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: hasPrevious ? 1 : 0,
          child: hasPrevious
              ? _buildButton(context, Strings.previous, onTap: onBack, enabled: true)
              : const SizedBox.shrink(),
        ),
        hasPrevious ? const SizedBox(width: 12) : const SizedBox.shrink(),
        // Next / Finish
        Expanded(
          flex: hasPrevious ? 1 : 2,
          child: _buildButton(
            context,
            isLast ? Strings.finish : Strings.next,
            enabled: isAnswerProvided,
            isPrimary: true,
            onTap: isAnswerProvided
                ? () {
                    if (isLast) {
                      onFinish();
                    } else {
                      onNext();
                    }
                  }
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildButton(
    BuildContext context,
    String text, {
    VoidCallback? onTap,
    bool enabled = true,
    bool isPrimary = false,
  }) {
    final colors = context.colors;

    final bgColor = isPrimary ? (enabled ? colors.accentSub : colors.white) : colors.accentWhite;
    final textColor = isPrimary ? (enabled ? colors.white : colors.black) : colors.black;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.center,
        child: text.text(16, 20, 500).c(textColor),
      ),
    );
  }
}
