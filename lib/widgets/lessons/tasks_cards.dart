import 'package:calora/common/extensions/bottom_sheet.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/domain/model/lesson/lesson_info.dart';
import 'package:calora/domain/model/workout/workout_request.dart';
import 'package:calora/widgets/lessons/lesson_card.dart' show LessonCard;
import 'package:calora/widgets/task/task_info_page.dart';
import 'package:calora/widgets/task/task_parametrs_widget.dart';
import 'package:flutter/material.dart';

class TasksCards extends StatelessWidget {
  final LessonInfo lessonInfo;
  final WorkoutRequest workout;

  TasksCards({super.key, required this.lessonInfo, required this.workout});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TaskParametersWidget(
          title: '${workout.id}-kun mashqlari bilan tanishing'.text(
            20,
            24,
            600,
          ),
          parameters: [
            ParameterItem(name: Strings.degree, value: 'Yengil'),
            ParameterItem(name: 'Kkal', value: '${workout.totalMetrics}'),
            ParameterItem(
              name: Strings.duration,
              value: '${lessonInfo.duration}',
            ),
          ],
          bottomLabel: Strings.exercises,
          bottomCount: lessonInfo.tasks.length,
          onChangePressed: () {},
        ),
        Expanded(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            itemCount: lessonInfo.tasks.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showTask(context, lessonInfo.tasks[index]),
                child: LessonCard(workout: workout),
              );
            },
            separatorBuilder: (BuildContext context, int index) {
              return SizedBox(height: 16);
            },
          ),
        ),
      ],
    );
  }

  void _showTask(BuildContext context, TaskInfo taskInfo) {
    context.showAppBottomSheet(child: TaskInfoPage(taskInfo: taskInfo));
  }
}
