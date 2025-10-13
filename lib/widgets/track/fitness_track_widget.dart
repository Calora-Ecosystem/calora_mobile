import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/date_and_time/date_and_time.dart';
import 'package:calora/domain/model/step/metrics_request.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/chart/chart_widget.dart';
import 'package:calora/widgets/steps/steps_indicator_widget.dart';
import 'package:flutter/material.dart';

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

  @override
  State<FitnessTrackWidget> createState() => _FitnessTrackWidgetState();
}

class _FitnessTrackWidgetState extends State<FitnessTrackWidget> {
  int offset = 0;
  String _getDateLabel(int index) {
    if (index == 0) return formatDateLabel(offset, "daily");
    if (index == 1) return formatDateLabel(offset, "weekly");
    return formatDateLabel(offset, "monthly");
  }

  @override
  Widget build(BuildContext context) {
    final tabController = DefaultTabController.of(context);
    final selected = widget.selectedDate ?? DateTime.now();

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
                borderRadius: const BorderRadius.all(Radius.circular(16)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () {
                          final tabController = DefaultTabController.of(context);
                          final index = tabController.index;
                          final selected = widget.selectedDate ?? DateTime.now();
                          changeOffset(index, selected, false);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Assets.icons.icBackward.svg(),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _getDateLabel(index).text(14, 16, 400).c(context.colors.textWhite),
                        ],
                      ),
                      InkWell(
                        onTap: () {
                          final tabController = DefaultTabController.of(context);
                          final index = tabController.index;
                          final selected = widget.selectedDate ?? DateTime.now();
                          changeOffset(index, selected, true);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Assets.icons.icForward.svg(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.colors.white,
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                    ),
                    child: RepaintBoundary(
                      key: widget.globalKey,
                      child: Column(
                        children: [
                          // pause va menu
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              InkWell(
                                onTap: widget.onClickMoreVert,
                                child: SizedBox(
                                  height: 18,
                                  width: 18,
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
                              onEditTap: () {
                                widget.onClickEditStepGoal();
                              },
                            )
                          else if (index == 1)
                            ChartWidget(
                              type: ChartType.weekly,
                              primaryValues: widget.primaryValues,
                              target: 2500,
                            )
                          else
                            ChartWidget(
                              type: ChartType.monthly,
                              primaryValues: widget.primaryValues,
                              target: 12000,
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
                                  '0 S'.text(16, 20, 500).c(context.colors.textStrong),
                                  const SizedBox(height: 2),
                                  Strings.onTime.text(14, 20, 400).c(context.colors.textSub),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Assets.icons.icDistance.svg(),
                                  const SizedBox(height: 4),
                                  '${widget.stepCount * 0.72}'
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
                                  '${widget.metrics.kcal}'
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
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void changeOffset(int index, DateTime selected, bool isForward) {
    final now = DateTime.now();
    DateTime nextDate;
    if (index == 0) {
      // daily
      nextDate = selected.add(Duration(days: isForward ? offset + 1 : offset - 1));
    } else if (index == 1) {
      // weekly
      nextDate = selected.add(Duration(days: (isForward ? offset + 1 : offset - 1) * 7));
    } else {
      // monthly
      nextDate = DateTime(selected.year, selected.month + (isForward ? offset + 1 : offset - 1));
    }
    if (isForward && nextDate.isAfter(now)) return;
    setState(() {
      offset += isForward ? 1 : -1;
      if (isForward) {
        widget.onClickForward();
      } else {
        widget.onClickBackward();
      }
    });
  }
}
