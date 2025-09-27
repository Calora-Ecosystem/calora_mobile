import 'package:calora/domain/model/lesson/lesson_info.dart';
import 'package:calora/widgets/lessons/lesson_card.dart' show LessonCard;
import 'package:flutter/material.dart';

class LessonsCards extends StatelessWidget {
  final List<LessonInfo> lessons;
  const LessonsCards({super.key, required this.lessons});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: lessons.length,
      itemBuilder: (context, index) {
        return LessonCard(lessonInfo: lessons[index]);
      },
      separatorBuilder: (BuildContext context, int index) {
        return SizedBox(height: 16);
      },
    );
  }
}
