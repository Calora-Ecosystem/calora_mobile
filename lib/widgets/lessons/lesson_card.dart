import 'package:calora/common/extensions/metrics_extension.dart';
import 'package:calora/common/extensions/number_extension/truncate.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/domain/model/workout/workout_request.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class LessonCard extends StatelessWidget {
  final WorkoutRequest workout;
  final bool isLocked;

  const LessonCard({super.key, required this.workout, required this.isLocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.colors.backgroundElevation,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              (workout.title).text(16, 20, 500).c(context.colors.textStrong),
              const SizedBox(height: 8),
              if (workout.hasRest)
                Strings.youCanRelaxTuday.text(14, 18, 500).c(context.colors.textSub)
              else
                ('${workout.totalDurationInMin} ${Strings.minute} • ${workout.kcal} ${Strings.kcal}')
                    .text(14, 18, 500)
                    .c(context.colors.textSub),
            ],
          ),
          const Spacer(),
          if (isLocked)
            Assets.icons.lock.svg()
          else if (workout.hasRest)
            Assets.icons.dayOffIcon.svg()
          else if (workout.isDone)
            Row(
              spacing: 8,
              children: [
                Strings.done.text(14, 18, 500).c(context.colors.accentSub),
                Assets.icons.doneLesson.svg(),
              ],
            )
          else
            Row(
              children: [
                CircularPercentIndicator(
                  radius: 10,
                  lineWidth: 2,
                  percent: workout.totalItems == 0 ? 0 : (workout.doneItems / workout.totalItems).clamp(0, 1),
                  backgroundColor: context.colors.accentWhite,
                  progressColor: context.colors.accentSub,
                ),
                const SizedBox(width: 8),
                '${(workout.totalItems == 0 ? 0 : (workout.doneItems / workout.totalItems * 100).asFixedTruncated(0))}%'
                    .text(14, 18, 500)
                    .c(context.colors.textSub),
              ],
            ),
        ],
      ),
    );
  }
}
