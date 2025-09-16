import 'package:freezed_annotation/freezed_annotation.dart';

part 'steps_stat.freezed.dart';
part 'steps_stat.g.dart';

@freezed
abstract class StepsWithMetrics with _$StepsWithMetrics {
  const factory StepsWithMetrics({
    required DateTime date,
    required String metric,
    required double value,
  }) = _StepsWithMetrics;

  factory StepsWithMetrics.fromJson(Map<String, dynamic> json) => _$StepsWithMetricsFromJson(json);
}
