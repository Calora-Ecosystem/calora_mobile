import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/domain/model/lesson/lesson_info.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class LessonCard extends StatelessWidget {
  final LessonCardData data;

  const LessonCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.colors.backgroundElevation,
        borderRadius: BorderRadius.circular(8),
      ),
      child: switch (data) {
        LessonData(:final lessonInfo) => Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ("${lessonInfo.id}-${Strings.day.toLowerCase()}")
                    .text(16, 20, 500)
                    .c(context.colors.textStrong),
                const SizedBox(height: 8),
                if (lessonInfo.isDayOff)
                  Strings.youCanRelaxTuday.text(14, 18, 500).c(context.colors.textSub)
                else
                  ("${lessonInfo.duration} minut • ${lessonInfo.calories} kkal")
                      .text(14, 18, 500)
                      .c(context.colors.textSub),
              ],
            ),
            const Spacer(),
            if (lessonInfo.isLocked)
              Assets.icons.lock.svg()
            else if (lessonInfo.isDayOff)
              Assets.icons.dayOffIcon.svg()
            else if (lessonInfo.isCompleted)
              Row(
                children: [
                  Strings.done.text(14, 18, 500).c(context.colors.accentSub),
                  const SizedBox(width: 8),
                  Assets.icons.done.svg(),
                ],
              )
            else
              Row(
                children: [
                  CircularPercentIndicator(
                    radius: 10,
                    lineWidth: 2,
                    percent: lessonInfo.level,
                    backgroundColor: context.colors.accentWhite,
                    progressColor: context.colors.accentSub,
                  ),
                  const SizedBox(width: 8),
                  ("${(lessonInfo.level * 100).toInt()}%")
                      .text(14, 18, 500)
                      .c(context.colors.textSub),
                ],
              ),
          ],
        ),
        TaskData(:final taskInfo) => Row(
          children: [
            Container(
              color: context.colors.white,
              height: 56,
              width: 56,
              child: Assets.images.task.image(width: 32, height: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  taskInfo.title.text(16, 20, 500).c(context.colors.textStrong),
                  const SizedBox(height: 8),
                  ("${taskInfo.count}").text(14, 18, 500).c(context.colors.textSub),
                ],
              ),
            ),
            if (taskInfo.isCompleted) Assets.icons.twoDone.svg() else Assets.icons.time.svg(),
          ],
        ),
      },
    );
  }
}
