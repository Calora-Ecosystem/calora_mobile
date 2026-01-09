import 'package:calora/common/extensions/number_extension/truncate.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/loading/shimmer.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class StepCardWidget extends StatelessWidget {
  final int currentSteps;
  final int targetSteps;
  final int timeInSeconds;
  final double distanceInKm;
  final int caloriesBurned;
  final bool loading;

  const StepCardWidget({
    super.key,
    required this.currentSteps,
    required this.targetSteps,
    required this.timeInSeconds,
    required this.distanceInKm,
    required this.caloriesBurned,
    required this.loading,
  });

  double get progressPercent {
    if (targetSteps == 0) return 0.0;
    final percent = currentSteps / targetSteps;
    return percent > 1.0 ? 1.0 : percent;
  }

  String get formattedTime {
    final hours = timeInSeconds ~/ 3600;
    final minutes = (timeInSeconds % 3600) ~/ 60;
    final seconds = timeInSeconds % 60;

    if (hours > 0) {
      return '$hours S $minutes D';
    } else if (minutes > 0) {
      return '$minutes D $seconds S';
    } else {
      return '$seconds S';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      loading: loading,
      shimmerChild: ShimmerChild(height: 204, radius: 20),
      child: Container(
        height: 204,
        padding: EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: context.colors.white,
        ),
        child: Column(
          spacing: 16,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Strings.yourStep.text(20, 24, 600),
                '$currentSteps'.text(24, 30, 700),
              ],
            ),
            Column(
              spacing: 4,
              children: [
                LinearPercentIndicator(
                  animation: true,
                  animateFromLastPercent: true,
                  percent: progressPercent,
                  lineHeight: 20,
                  progressColor: context.colors.blueAccent,
                  backgroundColor: context.colors.backgroundElevation,
                  padding: EdgeInsets.zero,
                  barRadius: const Radius.circular(8),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    '0'.text(14, 16, 400),
                    '$targetSteps'.text(14, 16, 400),
                  ],
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Assets.icons.icStopwatch.svg(),
                    const SizedBox(height: 4),
                    formattedTime
                        .text(16, 20, 500)
                        .c(context.colors.textStrong),
                    const SizedBox(height: 2),
                    Strings.onTime.text(14, 20, 400).c(context.colors.textSub),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Assets.icons.icDistance.svg(),
                    const SizedBox(height: 4),
                    distanceInKm
                        .asFixedTruncated(2)
                        .text(16, 20, 500)
                        .c(context.colors.textStrong),
                    const SizedBox(height: 2),
                    Strings.distanceInKm
                        .text(14, 20, 400)
                        .c(context.colors.textSub),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Assets.icons.icCalorie.svg(),
                    const SizedBox(height: 4),
                    '$caloriesBurned'
                        .text(16, 20, 500)
                        .c(context.colors.textStrong),
                    const SizedBox(height: 2),
                    Strings.calorie.text(14, 20, 400).c(context.colors.textSub),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
