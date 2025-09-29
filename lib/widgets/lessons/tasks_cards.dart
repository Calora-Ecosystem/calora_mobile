import 'package:calora/domain/model/lesson/lesson_info.dart';
import 'package:calora/widgets/lessons/lesson_card.dart' show LessonCard;
import 'package:flutter/material.dart';

class TasksCards extends StatelessWidget {
  final List<TaskInfo> tasks;

  TasksCards({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        return LessonCard(taskInfo: tasks[index]);
      },
      separatorBuilder: (BuildContext context, int index) {
        return SizedBox(height: 16);
      },
    );
  }
}
