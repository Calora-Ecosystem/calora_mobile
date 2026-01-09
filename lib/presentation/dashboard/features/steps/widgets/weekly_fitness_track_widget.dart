import 'package:calora/common/gen/strings.dart';
import 'package:calora/domain/model/step/metrics_request.dart';
import 'package:calora/presentation/dashboard/features/steps/widgets/base_fitness_track_widget.dart';
import 'package:calora/widgets/chart/chart_widget.dart';
import 'package:flutter/material.dart';

class WeeklyFitnessTrackWidget extends StatefulWidget {
  const WeeklyFitnessTrackWidget({
    super.key,
    required this.primaryValues,
    required this.goal,
    required this.metrics,
    required this.onClickForward,
    required this.onClickBackward,
    required this.onClickPause,
    required this.onClickMoreVert,
    this.selectedDate,
    this.offset = 0,
    this.loading = false,
  });

  final List<double> primaryValues;
  final int goal;
  final MetricsRequest metrics;
  final Function() onClickForward;
  final Function() onClickBackward;
  final Function() onClickPause;
  final Function() onClickMoreVert;
  final DateTime? selectedDate;
  final int offset;
  final bool loading;

  @override
  State<WeeklyFitnessTrackWidget> createState() =>
      _WeeklyFitnessTrackWidgetState();
}

class _WeeklyFitnessTrackWidgetState extends State<WeeklyFitnessTrackWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bool canGoForwardForThisTab = widget.offset < 0;
    return BaseFitnessTrackWidget(
      period: 'weekly',
      title: Strings.weekly,
      offset: widget.offset,
      canGoForward: canGoForwardForThisTab,
      onClickBackward: widget.onClickBackward,
      onClickForward: widget.onClickForward,
      onClickMoreVert: widget.onClickMoreVert,
      metrics: widget.metrics,
      body: ChartWidget(
        type: ChartType.weekly,
        primaryValues: widget.primaryValues,
        target: widget.goal.toDouble(),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
