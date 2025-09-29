import 'package:auto_route/auto_route.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/common/widgets/rating/rating_stars.dart';
import 'package:calora/domain/model/lesson/lesson_info.dart';
import 'package:calora/widgets/lessons/lesson_card.dart' show LessonCard;
import 'package:flutter/material.dart';

class LessonsCards extends StatelessWidget {
  final List<LessonInfo> lessons;
  final Level level;
  const LessonsCards({super.key, required this.lessons, required this.level});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: lessons.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => context.router.push(
            TasksRoute(tasks: lessons[index].tasks, id: index + 1, level: level),
          ),
          child: LessonCard(lessonInfo: lessons[index]),
        );
      },
      separatorBuilder: (BuildContext context, int index) {
        return SizedBox(height: 16);
      },
    );
  }
}
