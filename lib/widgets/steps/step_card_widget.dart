import 'dart:io';

import 'package:calora/common/di/injection.dart';
import 'package:calora/common/extensions/number_extension/truncate.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/service/step_counter_service.dart';
import 'package:calora/common/widgets/loading/shimmer.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/common/animated_count.dart';
import 'package:calora/widgets/health/health_sync_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class StepCardWidget extends StatelessWidget {
  final int currentSteps;
  final int targetSteps;
  final num timeInSeconds;
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

  /// Whether step data is currently being sourced from Apple Health /
  /// Health Connect. Drives the persistent sync label that identifies
  /// HealthKit functionality in the UI (App Store Review Guideline 2.5.1).
  bool get _isHealthSource =>
      getIt<StepCounterService>().source == StepSource.health;

  String get _healthSourceName =>
      Platform.isIOS ? 'Apple Health' : 'Health Connect';

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      loading: loading,
      shimmerChild: const ShimmerChild(height: 204, radius: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Strings.yourStep.text(18, 24, 600),
                    if (_isHealthSource) ...[
                      const SizedBox(height: 4),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => HealthSyncBottomSheet.show(context),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.favorite_rounded,
                              size: 12,
                              color: context.colors.accentSub,
                            ),
                            const SizedBox(width: 4),
                            _healthSourceName
                                .text(12, 16, 400)
                                .c(context.colors.textSub),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                AnimatedCount(
                  count: currentSteps,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
                ),
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
                    timeInSeconds.toDouble().asFixedTruncated(1).text(16, 20, 500).c(context.colors.textStrong),
                    const SizedBox(height: 2),
                    Strings.hour.text(14, 20, 400).c(context.colors.textSub),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Assets.icons.icDistance.svg(),
                    const SizedBox(height: 4),
                    distanceInKm.asFixedTruncated(2).text(16, 20, 500).c(context.colors.textStrong),
                    const SizedBox(height: 2),
                    Strings.distanceInKm.text(14, 20, 400).c(context.colors.textSub),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Assets.icons.icCalorie.svg(),
                    const SizedBox(height: 4),
                    '$caloriesBurned'.text(16, 20, 500).c(context.colors.textStrong),
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
