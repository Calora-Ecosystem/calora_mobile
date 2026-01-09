import 'package:calora/domain/model/workout/workout_request.dart';
import 'package:flutter/material.dart';

extension MetricsController on TextEditingController {
  void handleMetricsChange({
    required String metrics,
    required bool isUserEditing,
  }) {
    if (metrics.isEmpty || !isUserEditing) return;

    final currentValue = text;
    final selection = this.selection;

    if (selection.base.offset < currentValue.length - metrics.length) {
      return;
    }

    String numericValue = currentValue.replaceAll(RegExp(r'[^0-9.]'), '');

    if (numericValue.split('.').length > 2) {
      final parts = numericValue.split('.');
      numericValue = '${parts[0]}.${parts.sublist(1).join()}';
    }

    final newValue = '$numericValue $metrics';

    if (currentValue != newValue) {
      value = TextEditingValue(
        text: newValue,
        selection: TextSelection.collapsed(offset: numericValue.length),
      );
    }
  }
}

extension WorkoutRequestMetrics on WorkoutRequest {
  int getMetricSum(String metricName) {
    try {
      return totalMetrics
          .firstWhere((m) => m.metric.toLowerCase() == metricName.toLowerCase())
          .sum;
    } catch (_) {
      return 0;
    }
  }

  int get protein => getMetricSum('Protein');

  int get fat => getMetricSum('Fat');

  int get carb => getMetricSum('Carb');

  int get kcal => getMetricSum('Kcal');

  int get water => getMetricSum('Water');

  int get step => getMetricSum('Step');

  int get weight => getMetricSum('Weight');
}

extension TotalMetricListX on List<TotalMetric> {
  int sumOf(String metric) {
    return firstWhere(
      (e) => e.metric == metric,
      orElse: () => const TotalMetric(metric: '', sum: 0),
    ).sum;
  }
}
