import 'package:calora/common/gen/strings.dart';
import 'package:calora/domain/model/step/metrics_request.dart';
import 'package:calora/presentation/dashboard/features/steps/widgets/base_fitness_track_widget.dart';
import 'package:calora/widgets/steps/steps_indicator_widget.dart';
import 'package:flutter/material.dart';

class DailyFitnessTrackWidget extends StatefulWidget {
  const DailyFitnessTrackWidget({
    super.key,
    required this.stepCount,
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
  final int goal;
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
  State<DailyFitnessTrackWidget> createState() =>
      _DailyFitnessTrackWidgetState();
}

class _DailyFitnessTrackWidgetState extends State<DailyFitnessTrackWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BaseFitnessTrackWidget(
      period: 'daily',
      title: Strings.daily,
      offset: widget.offset,
      canGoForward: widget.canGoForward,
      onClickBackward: widget.onClickBackward,
      onClickForward: widget.onClickForward,
      onClickMoreVert: widget.onClickMoreVert,
      metrics: widget.metrics,
      body: StepsIndicatorWidget(
        current: widget.stepCount.toDouble(),
        goal: widget.goal,
        onEditTap: () => widget.onClickEditStepGoal(),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
