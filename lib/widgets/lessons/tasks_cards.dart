import 'package:auto_route/auto_route.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/domain/model/lesson/lesson_info.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/lessons/lesson_card.dart' show LessonCard;
import 'package:calora/widgets/task/task_info_page.dart';
import 'package:calora/widgets/task/task_parametrs_widget.dart';
import 'package:flutter/material.dart';

class TasksCards extends StatelessWidget {
  final LessonInfo lessonInfo;

  TasksCards({super.key, required this.lessonInfo});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TaskParametrsWidget(id: lessonInfo.id, lessonInfo: lessonInfo),
        Expanded(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            itemCount: lessonInfo.tasks.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => context.router.push(TaskRoute(taskInfo: lessonInfo.tasks[index])),
                child: LessonCard(data: TaskData(lessonInfo.tasks[index])),
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
    showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: context.colors.white,
      context: context,
      builder: (context) {
        return TaskInfoPage(taskInfo: taskInfo);
      },
    );
  }
}
