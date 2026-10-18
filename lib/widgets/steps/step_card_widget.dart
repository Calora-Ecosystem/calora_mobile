import 'dart:io';

import 'package:calora/common/di/injection.dart';
import 'package:calora/common/extensions/number_extension/truncate.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/service/step_counter_service.dart';
import 'package:calora/common/widgets/loading/shimmer.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/step_sources/step_connect.dart';
import 'package:calora/presentation/step_sources/step_tracking_tile.dart';
import 'package:calora/widgets/common/animated_count.dart';
import 'package:calora_steps/calora_steps.dart';
import 'package:easy_localization/easy_localization.dart';
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

  bool get _isHealthSource =>
      getIt<StepCounterService>().source == StepSource.health;

  Widget _sourceLabel(BuildContext context) {
    if (Platform.isIOS) {
      if (!_isHealthSource) return const SizedBox.shrink();
      return _SourceLabel(
        icon: Icons.favorite_rounded,
        text: 'Apple Health',
        color: context.colors.textSub,
        iconColor: context.colors.accentSub,
      );
    }
    final counter = getIt<StepCounterService>();
    return StreamBuilder<StepSnapshot>(
      stream: counter.snapshots,
      initialData: counter.lastSnapshot,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null) return const SizedBox.shrink();
        if (isStepCountingBlocked(data.issue)) {
          return _SourceLabel(
            icon: Icons.error_rounded,
            text: 'steps_card_not_counting'.tr(),
            color: context.colors.errorBase,
            iconColor: context.colors.errorBase,
          );
        }
        final viaHealthConnect = data.source == StepSourceKind.healthConnect;
        return _SourceLabel(
          icon: viaHealthConnect
              ? Icons.favorite_rounded
              : Icons.directions_walk_rounded,
          text: viaHealthConnect
              ? 'steps_card_source_hc'.tr()
              : 'steps_source_sensor'.tr(),
          color: context.colors.textSub,
          iconColor: context.colors.accentSub,
        );
      },
    );
  }

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
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: Platform.isAndroid || _isHealthSource
                        ? () => openStepTracking(context)
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Strings.yourStep.text(18, 24, 600),
                        const SizedBox(height: 4),
                        _sourceLabel(context),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedCount(
                  count: currentSteps,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
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
                    timeInSeconds
                        .toDouble()
                        .asFixedTruncated(1)
                        .text(16, 20, 500)
                        .c(context.colors.textStrong),
                    const SizedBox(height: 2),
                    Strings.hour.text(14, 20, 400).c(context.colors.textSub),
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

class _SourceLabel extends StatelessWidget {
  const _SourceLabel({
    required this.icon,
    required this.text,
    required this.color,
    required this.iconColor,
  });

  final IconData icon;
  final String text;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 12, color: iconColor),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              height: 16 / 12,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
