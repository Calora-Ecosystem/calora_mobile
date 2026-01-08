import 'package:calora/common/extensions/number_extension/truncate.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/date_and_time/date_and_time.dart';
import 'package:calora/common/widgets/loading/shimmer.dart';
import 'package:calora/domain/model/step/metrics_request.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/dashboard/features/steps/management/steps_manager.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

class BaseFitnessTrackWidget extends StatelessWidget {
  const BaseFitnessTrackWidget({
    super.key,
    required this.body,
    required this.metrics,
    required this.onClickForward,
    required this.onClickBackward,
    required this.onClickMoreVert,
    this.selectedDate,
    this.canGoForward = true,
    this.offset = 0,
    this.loading = false,
    required this.period,
    this.title,
  });

  final Widget body;
  final MetricsRequest metrics;
  final Function() onClickForward;
  final Function() onClickBackward;
  final Function() onClickMoreVert;
  final DateTime? selectedDate;
  final bool canGoForward;
  final int offset;
  final bool loading;
  final String period;
  final String? title;

  String _getDateLabel(String period) {
    return formatDateLabel(offset, period);
  }

  @override
  Widget build(BuildContext context) {
    final StepsManager manager = context.read<StepsManager>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: context.colors.accentSub,
            borderRadius: const BorderRadius.all(Radius.circular(20)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: onClickBackward,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Assets.icons.icBackward.svg(),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _getDateLabel(
                        period,
                      ).text(14, 16, 400).c(context.colors.textWhite),
                    ],
                  ),
                  canGoForward
                      ? InkWell(
                          onTap: onClickForward,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Assets.icons.icForward.svg(),
                          ),
                        )
                      : const SizedBox(width: 48, height: 24),
                ],
              ),
              const SizedBox(height: 6),
              ShimmerWrapper(
                loading: manager.state.isGettingSteps,
                shimmerChild: const ShimmerChild(
                  height: 400,
                  width: double.maxFinite,
                  radius: 20,
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.colors.white,
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                  ),
                  child: RepaintBoundary(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (title != null)
                              title!
                                  .text(14, 18, 600)
                                  .c(context.colors.neutralPrimary)
                            else
                              const SizedBox.shrink(),
                            InkWell(
                              onTap: onClickMoreVert,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                color: Colors.transparent,
                                height: 32,
                                width: 32,
                                child: Assets.icons.icMoreVert.svg(),
                              ),
                            ),
                          ],
                        ),
                        if (title != null) const SizedBox(height: 12),
                        body,
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Assets.icons.icStopwatch.svg(),
                                const SizedBox(height: 4),
                                '0 S'
                                    .text(16, 20, 500)
                                    .c(context.colors.textStrong),
                                const SizedBox(height: 2),
                                Strings.onTime
                                    .text(14, 20, 400)
                                    .c(context.colors.textSub),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Assets.icons.icDistance.svg(),
                                const SizedBox(height: 4),
                                (metrics.distance)
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
                                '${metrics.kcal}'
                                    .text(16, 20, 500)
                                    .c(context.colors.textStrong),
                                const SizedBox(height: 2),
                                Strings.calorie
                                    .text(14, 20, 400)
                                    .c(context.colors.textSub),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
