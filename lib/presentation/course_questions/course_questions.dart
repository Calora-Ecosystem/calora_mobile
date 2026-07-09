import 'package:auto_route/auto_route.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/common/widgets/button/navigation_button.dart';
import 'package:calora/presentation/course_questions/management/course_questions_management.dart';
import 'package:calora/presentation/course_questions/management/course_questions_manager.dart';
import 'package:calora/widgets/progress/progress_page.dart';
import 'package:calora/widgets/questions/course_questions_body_widget.dart';
import 'package:calora/widgets/questions/question_progress_widget.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

@RoutePage()
class CourseQuestionsPage
    extends Managed<CourseQuestionsManager, CourseQuestionsState, CourseQuestionsEffect> {
  final int courseId;
  final String imageUrl;

  const CourseQuestionsPage({super.key, required this.courseId, required this.imageUrl});

  @override
  void init(context, manager) {}

  @override
  Widget builder(context, manager, state) {
    final total = 3;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Assets.icons.background.image(fit: BoxFit.fill),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      QuestionProgressWidget(
                        title: Strings.weHaveQuestions,
                        current: state.currentIndex + 1,
                        total: total,
                      ),
                      const SizedBox(height: 16),
                      CourseQuestionsBodyWidget(),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: NavigationButtons(
                      currentIndex: state.currentIndex,
                      total: total,
                      isAnswerProvided: manager.isAnswerProvided,
                      onNext: manager.next,
                      onBack: manager.back,
                      onFinish: () {
                        context.router.popUntilRoot();
                        context.router.push(
                          ProgressRoute(
                            key: UniqueKey(),
                            nextRoute: LessonsRoute(courseId: courseId, imageUrl: imageUrl),
                            apiCall: () => manager.finish(courseId: courseId),
                            title: Strings.weWillMakeDailyPlan,
                            analyzeItems: [
                              ProgressAnalyzeItem(
                                text: Strings.weAreAnalyzingYourActivityLevel,
                                threshold: 0.3,
                              ),
                              ProgressAnalyzeItem(
                                text: Strings.configuringSmartReminderPlan,
                                threshold: 0.5,
                              ),
                              ProgressAnalyzeItem(
                                text: Strings.additionalInformationBeingAnalyzed,
                                threshold: 0.8,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
