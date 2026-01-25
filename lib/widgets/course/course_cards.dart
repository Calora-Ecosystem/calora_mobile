import 'package:calora/domain/model/course/course_request.dart';
import 'package:calora/widgets/course/course_card.dart';
import 'package:flutter/material.dart';

class CourseCards extends StatelessWidget {
  final List<CourseRequest> courses;
  final Map<int, VoidCallback> onTapCallbacks;

  const CourseCards({
    super.key,
    required this.courses,
    required this.onTapCallbacks,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return CourseCard(
          onTap: onTapCallbacks[course.id] ?? () {},
          course: course,
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 20),
    );
  }
}
