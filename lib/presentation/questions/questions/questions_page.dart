import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/common/action/actions_page.dart';
import 'package:calora/widgets/questions/question_progress_widget.dart';
import 'package:calora/widgets/questions/questions_body_widget.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

import '../../../common/gen/strings.dart';
import 'management/questions_management.dart';
import 'management/questions_manager.dart';

@RoutePage()
class QuestionsPage
    extends Managed<QuestionsManager, QuestionsState, QuestionsEffect> {
  QuestionsPage({super.key});

  @override
  Widget builder(
    BuildContext context,
    QuestionsManager manager,
    QuestionsState state,
  ) {
    final profile = state.answers;

    final currentAnswer = switch (state.currentIndex) {
      0 => profile?.name,
      1 => profile?.gender,
      2 => profile?.purposeIds,
      3 => profile?.birthDate,
      4 => profile?.height,
      5 => profile?.weight,
      6 => profile?.targetWeight,
      7 => profile?.activityHours,
      _ => null,
    };

    return Scaffold(
      body: Stack(
        children: [
          // Positioned.fill(child: Assets.icons.background.image(fit: BoxFit.fill)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          showActionsSheet(context);
                        },
                        child: Text('data'),
                      ),
                      QuestionProgressWidget(
                        current: state.currentIndex + 1,
                        total: 8,
                      ),
                      const SizedBox(height: 16),
                      QuestionsBodyWidget(),
                    ],
                  ),
                  _buildNavigationButtons(
                    context,
                    manager,
                    state,
                    8,
                    currentAnswer != null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(
    BuildContext context,
    QuestionsManager manager,
    QuestionsState state,
    int total,
    bool isAnswerProvided,
  ) {
    final isLast = state.currentIndex == total - 1;
    final hasPrevious = state.currentIndex > 0;

    return Row(
      children: [
        Expanded(
          flex: hasPrevious ? 1 : 0,
          child: hasPrevious
              ? _buildButton(
                  context,
                  Strings.previous,
                  onTap: manager.back,
                  enabled: true,
                )
              : const SizedBox.shrink(),
        ),
        hasPrevious ? const SizedBox(width: 12) : const SizedBox.shrink(),
        Expanded(
          flex: hasPrevious ? 1 : 2,
          child: _buildButton(
            context,
            isLast ? Strings.finish : Strings.next,
            enabled: isAnswerProvided,
            onTap: isAnswerProvided
                ? () {
                    if (isLast) {
                      manager.finish();
                    } else {
                      manager.next();
                    }
                  }
                : null,
            isPrimary: true,
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
    final bgColor = isPrimary
        ? (enabled ? colors.neutral600Secondary : colors.accentWhite)
        : colors.accentWhite;
    final textColor = isPrimary
        ? (enabled ? Colors.white : Colors.black)
        : Colors.black;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: text
            .text(16, 20, 500)
            .c(textColor)
            .copyWith(textAlign: TextAlign.center),
      ),
    );
  }

  void showActionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const ActionsPage(),
    );
  }
}
