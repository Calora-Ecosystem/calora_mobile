import 'package:calora/common/gen/strings.dart';
import 'package:calora/domain/model/step/metrics_request.dart';
import 'package:calora/presentation/dashboard/features/steps/widgets/base_fitness_track_widget.dart';
import 'package:calora/widgets/chart/chart_widget.dart';
import 'package:flutter/material.dart';

class MonthlyFitnessTrackWidget extends StatefulWidget {
  const MonthlyFitnessTrackWidget({
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
  State<MonthlyFitnessTrackWidget> createState() =>
      _MonthlyFitnessTrackWidgetState();
}

class _MonthlyFitnessTrackWidgetState extends State<MonthlyFitnessTrackWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bool canGoForwardForThisTab = widget.offset < 0;
    return BaseFitnessTrackWidget(
      period: 'monthly',
      title: Strings.monthly,
      offset: widget.offset,
      canGoForward: canGoForwardForThisTab,
      onClickBackward: widget.onClickBackward,
      onClickForward: widget.onClickForward,
      onClickMoreVert: widget.onClickMoreVert,
      metrics: widget.metrics,
      loading: widget.loading,
      body: ChartWidget(
        type: ChartType.monthly,
        primaryValues: widget.primaryValues,
        target: widget.goal.toDouble(),
        periodStart: _monthStart(),
      ),
    );
  }

  /// First day of the month this tab is showing (offset 0 = current month).
  DateTime _monthStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + widget.offset, 1);
  }

  @override
  bool get wantKeepAlive => true;
}
