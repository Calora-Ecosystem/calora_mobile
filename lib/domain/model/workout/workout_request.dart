import 'package:freezed_annotation/freezed_annotation.dart';

part 'workout_request.freezed.dart';
part 'workout_request.g.dart';

@freezed
abstract class WorkoutRequest with _$WorkoutRequest {
  const factory WorkoutRequest({
    required int id,
    required int courseId,
    required String title,
    required bool hasRest,
    required int totalItems,
    required int doneItems,
    required bool isDone,
    required int totalDurationInMin,
    required List<TotalMetric> totalMetrics,
    required int order,
  }) = _WorkoutRequest;

  factory WorkoutRequest.fromJson(Map<String, dynamic> json) => _$WorkoutRequestFromJson(json);
}

@freezed
abstract class TotalMetric with _$TotalMetric {
  const factory TotalMetric({
    required String metric,
    required int sum,
  }) = _TotalMetric;

  factory TotalMetric.fromJson(Map<String, dynamic> json) => _$TotalMetricFromJson(json);
}
