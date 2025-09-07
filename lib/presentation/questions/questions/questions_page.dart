import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/questions/question_progress.dart';
import 'package:calora/widgets/questions/questions_body.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

import '../../../common/gen/assets.gen.dart';
import '../../../common/gen/strings.dart';
import 'management/questions_management.dart';
import 'management/questions_manager.dart';

@RoutePage()
class QuestionsPage extends Managed<QuestionsManager, QuestionsState, QuestionsEffect> {
  QuestionsPage({super.key});

  @override
  Widget builder(BuildContext context, QuestionsManager manager, QuestionsState state) {
    final total = 8;

    final profile = state.answers;

    final answers = [
      profile?.name,
      profile?.gender,
      profile?.purposeIds,
      profile?.birthDate,
      profile?.height,
      profile?.weight,
      profile?.targetWeight,
      profile?.activityHours,
    ];
    final currentAnswer = answers[state.currentIndex];

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Assets.icons.background.image(fit: BoxFit.fill)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      QuestionProgress(current: state.currentIndex + 1, total: total),
                      const SizedBox(height: 16),
                      QuestionsBody(),
                    ],
                  ),
                  Row(
                    children: [
                      if (state.currentIndex > 0)
                        Expanded(
                          child: _buildButton(
                            context,
                            Strings.previous,
                            onTap: manager.back,
                            enabled: manager.getButtonStatus(),
                          ),
                        ),
                      if (state.currentIndex > 0) const SizedBox(width: 12),
                      Expanded(
                        child: _buildButton(
                          context,
                          state.currentIndex == total - 1 ? Strings.finish : Strings.next,
                          enabled: manager.getButtonStatus(),
                          onTap: currentAnswer != null
                              ? () {
                                  if (state.currentIndex == total - 1) {
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
        ? (enabled ? colors.strokeAccent : colors.accentWhite)
        : colors.accentWhite;

    final textColor = isPrimary ? (enabled ? Colors.white : Colors.black) : Colors.black;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
        child: text.text(16, 20, 500).c(textColor).copyWith(textAlign: TextAlign.center),
      ),
    );
  }
}
