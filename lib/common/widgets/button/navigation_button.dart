import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class NavigationButtons extends StatelessWidget {
  final int currentIndex;
  final int total;
  final bool isAnswerProvided;
  final bool isLoading;
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
    this.isLoading = false,
  });

  bool get isLast => currentIndex == total - 1;
  bool get hasPrevious => currentIndex > 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [_buildBackButton(context), _buildMainButton(context)],
    );
  }

  Widget _buildBackButton(BuildContext context) {
    if (!hasPrevious) return const SizedBox.shrink();

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: _buildButton(
          context,
          Strings.previous,
          onTap: onBack,
          enabled: true,
          isPrimary: false,
        ),
      ),
    );
  }

  Widget _buildMainButton(BuildContext context) {
    return Expanded(
      flex: hasPrevious ? 1 : 2,
      child: _buildActionButton(context),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    if (isLast) {
      return Button(
        loading: isLoading,
        text: Strings.finish,
        textColor: context.colors.textWhite,
        onPressed: isAnswerProvided ? onFinish : null,
      );
    }
    return _buildButton(
      context,
      Strings.next,
      enabled: isAnswerProvided,
      isPrimary: true,
      onTap: isAnswerProvided ? onNext : null,
    );
  }

  Widget _buildButton(
    BuildContext context,
    String text, {
    VoidCallback? onTap,
    required bool enabled,
    required bool isPrimary,
  }) {
    final colors = context.colors;

    final bgColor = isPrimary
        ? (enabled ? colors.accentSub : colors.white)
        : colors.accentWhite;

    final textColor = isPrimary
        ? (enabled ? colors.white : colors.black)
        : colors.black;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: text.text(16, 20, 500).c(textColor),
      ),
    );
  }
}
