import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/chart/chart_widget.dart';
import 'package:calora/widgets/steps/steps_indicator_widget.dart';
import 'package:flutter/material.dart';

class FitnessTrackWidget extends StatefulWidget {
  const FitnessTrackWidget({
    super.key,
    required this.steps,
    required this.distance,
    required this.onClickForward,
    required this.onClickBackward,
    required this.onClickPause,
    required this.onClickMoreVert,
    required this.onClickEditStepGoal,
    this.selectedDate,
  });

  final int steps;
  final int distance;
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
  int goal = 100000;

  @override
  Widget build(BuildContext context) {
    final tabController = DefaultTabController.of(context);

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
                        onTap: widget.onClickBackward,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Assets.icons.icBackward.svg(),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          "Bugun".text(14, 16, 400).c(context.colors.textWhite),
                          const SizedBox(height: 4),
                          "7- sentabr".text(14, 16, 400).c(context.colors.textWhite),
                        ],
                      ),
                      InkWell(
                        onTap: widget.onClickForward,
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
                    child: Column(
                      children: [
                        // pause va menu
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: widget.onClickPause,
                              child: SizedBox(
                                height: 18,
                                width: 18,
                                child: Assets.icons.icPause.svg(),
                              ),
                            ),
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
                            current: widget.steps,
                            goal: goal,
                            onEditTap: () {
                              widget.onClickEditStepGoal();
                            },
                          )
                        else if (index == 1)
                          ChartWidget(
                            type: ChartType.weekly,
                            primaryValues: [1000, 2000, 3000, 1500, 4000, 2500, 5000],
                            target: 2500,
                            total: 19000,
                          )
                        else
                          ChartWidget(
                            type: ChartType.monthly,
                            primaryValues: [10000, 12000, 8000, 15000],
                            target: 12000,
                            total: 45000,
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
                                '${widget.distance}'.text(16, 20, 500).c(context.colors.textStrong),
                                const SizedBox(height: 2),
                                Strings.distanceInKm.text(14, 20, 400).c(context.colors.textSub),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Assets.icons.icCalorie.svg(),
                                const SizedBox(height: 4),
                                '0'.text(16, 20, 500).c(context.colors.textStrong),
                                const SizedBox(height: 2),
                                Strings.calorie.text(14, 20, 400).c(context.colors.textSub),
                              ],
                            ),
                          ],
                        ),
                      ],
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
