import 'package:freezed_annotation/freezed_annotation.dart';

part 'steps_stat.freezed.dart';
part 'steps_stat.g.dart';

@freezed
abstract class StepsWithMetricsRequest with _$StepsWithMetricsRequest {
  const factory StepsWithMetricsRequest({
    required DateTime date,
    @Default("Step") String metric,
    required double value,
  }) = _StepsWithMetricsRequest;

  factory StepsWithMetricsRequest.fromJson(Map<String, dynamic> json) =>
      _$StepsWithMetricsRequestFromJson(json);
}
