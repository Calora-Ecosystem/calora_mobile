import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/domain/model/lesson/lesson_info.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class TaskParametrsWidget extends StatelessWidget {
  final int id;
  final LessonInfo lessonInfo;
  const TaskParametrsWidget({super.key, required this.id, required this.lessonInfo});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        '${id}-kun mashqlari bilan tanishing'.text(20, 24, 600).c(context.colors.textStrong),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(child: _buildTaskParametrs(Strings.degree, 'Yengil', context)),
            Expanded(
              child: Container(
                margin: EdgeInsets.only(right: 12),
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.symmetric(
                    vertical: BorderSide(color: context.colors.neutral200Stroke),
                  ),
                ),
                child: _buildTaskParametrs('kkal', lessonInfo.calories.toString(), context),
              ),
            ),
            Expanded(
              child: _buildTaskParametrs(Strings.duration, lessonInfo.duration.toString(), context),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Strings.exercises.text(16, 20, 500),
            SizedBox(width: 4),
            ('(' + lessonInfo.tasks.length.toString() + ')')
                .text(16, 20, 500)
                .c(context.colors.neutral600Secondary),
            Spacer(),
            TextButton(
              onPressed: () {},
              child: Strings.change.text(14, 16, 600).c(context.colors.accentSub),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTaskParametrs(String parameterName, String parameterValue, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        parameterValue.text(16, 20, 500).c(context.colors.neutral900Primary),
        parameterName.text(14, 18, 400).c(context.colors.neutral600Secondary),
      ],
    );
  }
}
