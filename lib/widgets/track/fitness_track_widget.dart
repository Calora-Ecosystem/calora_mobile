import 'package:calora/common/extensions/number_extension/truncate.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/date_and_time/date_and_time.dart';
import 'package:calora/common/widgets/loading/shimmer.dart';
import 'package:calora/domain/model/step/metrics_request.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/dashboard/features/steps/management/steps_manager.dart';
import 'package:calora/widgets/chart/chart_widget.dart';
import 'package:calora/widgets/steps/steps_indicator_widget.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

class FitnessTrackWidget extends StatefulWidget {
  const FitnessTrackWidget({
    super.key,
    required this.primaryValues,
    required this.stepCount,
    required this.globalKey,
    required this.goal,
    required this.metrics,
    required this.onClickForward,
    required this.onClickBackward,
    required this.onClickPause,
    required this.onClickMoreVert,
    required this.onClickEditStepGoal,
    this.selectedDate,
    this.canGoForward = true,
    this.offset = 0,
    this.loading = false,
  });

  final int stepCount;
  final List<double> primaryValues;
  final int goal;
  final GlobalKey globalKey;
  final MetricsRequest metrics;
  final Function() onClickForward;
  final Function() onClickBackward;
  final Function() onClickPause;
  final Function() onClickMoreVert;
  final Function() onClickEditStepGoal;
  final DateTime? selectedDate;
  final bool canGoForward;
  final int offset;
  final bool loading;

  @override
  State<FitnessTrackWidget> createState() => _FitnessTrackWidgetState();
}

class _FitnessTrackWidgetState extends State<FitnessTrackWidget> {
  String _getDateLabel(int index) {
    if (index == 0) return formatDateLabel(widget.offset, 'daily');
    if (index == 1) return formatDateLabel(widget.offset, 'weekly');
    return formatDateLabel(widget.offset, 'monthly');
  }

  @override
  Widget build(BuildContext context) {
    final tabController = DefaultTabController.of(context);
    final StepsManager manager = context.read<StepsManager>();

    return AnimatedBuilder(
      animation: tabController,
      builder: (context, _) {
        final index = tabController.index;
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
                        onTap: widget.onClickBackward,
                        child: Padding(padding: const EdgeInsets.only(left: 16), child: Assets.icons.icBackward.svg()),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [_getDateLabel(index).text(14, 16, 400).c(context.colors.textWhite)],
                      ),
                      widget.canGoForward
                          ? InkWell(
                              onTap: widget.onClickForward,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: Assets.icons.icForward.svg(),
                              ),
                            )
                          : SizedBox(width: 48, height: 24),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ShimmerWrapper(
                    loading: manager.state.isGettingSteps,
                    shimmerChild: ShimmerChild(
                      height: index == 0
                          ? 358
                          : index == 1
                          ? 370
                          : 430,
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
                        key: widget.globalKey,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ((index == 1)
                                        ? Strings.weeklyResults
                                        : index == 2
                                        ? Strings.monthlyResults
                                        : '')
                                    .text(14, 18, 600)
                                    .c(context.colors.neutralPrimary),
                                InkWell(
                                  onTap: widget.onClickMoreVert,
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
                            const SizedBox(height: 12),
                            if (index == 0)
                              StepsIndicatorWidget(
                                current: widget.stepCount.toDouble(),
                                goal: widget.goal,
                                onEditTap: () => widget.onClickEditStepGoal(),
                              )
                            else if (index == 1)
                              ChartWidget(
                                type: ChartType.weekly,
                                primaryValues: widget.primaryValues,
                                target: widget.goal.toDouble(),
                              )
                            else
                              ChartWidget(
                                type: ChartType.monthly,
                                primaryValues: widget.primaryValues,
                                target: widget.goal.toDouble(),
                              ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Assets.icons.icStopwatch.svg(),
                                    const SizedBox(height: 4),
                                    widget.metrics.duration.toString().text(16, 20, 500).c(context.colors.textStrong),
                                    const SizedBox(height: 2),
                                    Strings.onTime.text(14, 20, 400).c(context.colors.textSub),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Assets.icons.icDistance.svg(),
                                    const SizedBox(height: 4),
                                    (widget.metrics.distance)
                                        .asFixedTruncated(2)
                                        .text(16, 20, 500)
                                        .c(context.colors.textStrong),
                                    const SizedBox(height: 2),
                                    Strings.distanceInKm.text(14, 20, 400).c(context.colors.textSub),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Assets.icons.icCalorie.svg(),
                                    const SizedBox(height: 4),
                                    '${widget.metrics.kcal}'.text(16, 20, 500).c(context.colors.textStrong),
                                    const SizedBox(height: 2),
                                    Strings.calorie.text(14, 20, 400).c(context.colors.textSub),
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
      },
    );
  }
}
