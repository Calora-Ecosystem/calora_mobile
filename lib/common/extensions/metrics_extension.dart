import 'package:calora/domain/model/step/metrics_request.dart';
import 'package:calora/domain/model/workout/workout_request.dart';
import 'package:flutter/material.dart';

/// Derives walking metrics (duration / distance / calories) from a raw step
/// count, entirely on-device. Used for the *today* daily view so the
/// Soat / Km / Kaloriya figures always match the live step number and
/// update in real time, instead of waiting on the backend's periodic
/// recompute (which is empty until the first 1-minute sync lands).
///
/// Estimates use widely-used averages:
///  • stride ≈ 0.715 m  → distance = steps × 0.000715 km
///  • energy ≈ 0.04 kcal per step (scaled by weight when known)
///  • cadence ≈ 100 steps/min → duration in hours = steps / 6000
MetricsRequest deriveMetricsFromSteps(int steps, {double? weightKg}) {
  if (steps <= 0) {
    return const MetricsRequest(foots: 0, distance: 0, kcal: 0, duration: 0);
  }

  final distanceKm = steps * 0.000715;
  final kcal = (steps * 0.04 * ((weightKg ?? 70) / 70)).round();

  final hours = steps / 6000.0;
  // Show "0" for negligible time, otherwise one decimal (e.g. 1.5).
  final num duration = hours < 0.1 ? 0 : (hours * 10).round() / 10;

  return MetricsRequest(
    foots: steps,
    distance: distanceKm,
    kcal: kcal,
    duration: duration,
  );
}

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

  int get kcal => totalKcal > 0 ? totalKcal : getMetricSum('Kcal');

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
