import 'package:auto_route/auto_route.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/common/widgets/button/navigation_button.dart';
import 'package:calora/presentation/common/action/actions_page.dart';
import 'package:calora/presentation/questions/questions/management/questions_management.dart';
import 'package:calora/presentation/questions/questions/management/questions_manager.dart';
import 'package:calora/widgets/questions/question_progress_widget.dart';
import 'package:calora/widgets/questions/questions_body_widget.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

@RoutePage()
class QuestionsPage extends Managed<QuestionsManager, QuestionsState, QuestionsEffect> {
  QuestionsPage({super.key});

  @override
  void listener(BuildContext context, QuestionsManager manager, QuestionsEffect effect) {
    effect.mapOrNull(
      withType: (e) {
        switch (e.type) {
          case QuestionsEffectType.success:
            pushProgressPage(context);
            break;
          case QuestionsEffectType.error:
            break;
          case QuestionsEffectType.empty:
            break;
        }
      },
    );
    super.listener(context, manager, effect);
  }

  @override
  Widget builder(BuildContext context, QuestionsManager manager, QuestionsState state) {
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
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(child: Assets.icons.background.image(fit: BoxFit.fill)),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        QuestionProgressWidget(
                          title: Strings.weHaveQuestions,
                          current: state.currentIndex + 1,
                          total: 8,
                        ),
                        const SizedBox(height: 16),
                        QuestionsBodyWidget(),
                        SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 10 : 30,
                    top: 10,
                  ),
                  child: NavigationButtons(
                    isLoading: state.isLoading,
                    currentIndex: state.currentIndex,
                    total: 8,
                    isAnswerProvided: currentAnswer != null,
                    onNext: manager.next,
                    onBack: manager.back,
                    onFinish: manager.finish,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void pushProgressPage(BuildContext context) {
    context.router.push(
      ProgressRoute(mode: 2, fetchGoals: true, nextRoute: const CalculateRoute()),
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
