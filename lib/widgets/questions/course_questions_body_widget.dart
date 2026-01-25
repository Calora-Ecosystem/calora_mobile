import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/course_questions/management/course_questions_manager.dart';
import 'package:calora/widgets/questions/purposes_widget.dart';
import 'package:calora/widgets/questions/questions_widget.dart'
    show QuestionWidget;
import 'package:flutter/cupertino.dart';
import 'package:management/management.dart';

class CourseQuestionsBodyWidget extends StatefulWidget {
  const CourseQuestionsBodyWidget({super.key});

  @override
  State<CourseQuestionsBodyWidget> createState() =>
      _CourseQuestionsBodyWidgetState();
}

class _CourseQuestionsBodyWidgetState extends State<CourseQuestionsBodyWidget> {
  List<String> degrees = [
    Strings.easyStart,
    Strings.withoutOverload,
    Strings.returnToActivity,
    Strings.increaseActivity,
    Strings.highLevelActivity,
  ];
  List<String> conditions = [Strings.iAmFine, Strings.minimumLoad];

  @override
  Widget build(BuildContext context) {
    final manager = context.read<CourseQuestionsManager>();
    return IndexedStack(
      index: manager.state.currentIndex,
      children: [
        QuestionWidget(
          questionText: Strings.enterYourPhysicalCondition,
          child: PurposesWidget(
            onPurposeSelected: (value) {
              manager.setAnswer(condition: value);
            },
            goals: conditions,
          ),
          icon: Assets.icons.bodyPartMuscle.svg(),
        ),
        QuestionWidget(
          questionText: Strings.activePerDay,
          child: PurposesWidget(
            onPurposeSelected: (value) {
              manager.setAnswer(activityTime: value);
            },
            goals: degrees,
          ),
          icon: Assets.icons.body.svg(),
        ),
        QuestionWidget(
          questionText: Strings.enterWorkoutTime,
          child: Container(
            decoration: BoxDecoration(
              color: context.colors.backgroundElevation,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
            height: 200,
            child: CupertinoPicker(
              itemExtent: 40,
              magnification: 1.2,
              squeeze: 1.2,
              selectionOverlay: null,
              onSelectedItemChanged: (index) {
                final time = '${index.toString().padLeft(2, '0')}:00';
                manager.setAnswer(trainingTime: time);
              },
              children: List.generate(24, (index) {
                final time = '${index.toString().padLeft(2, '0')}:00';
                return Center(
                  child: time.text(35.8, 40, 400).c(context.colors.textPrimary),
                );
              }),
            ),
          ),
          icon: Assets.icons.body.svg(),
        ),
      ],
    );
  }
}
