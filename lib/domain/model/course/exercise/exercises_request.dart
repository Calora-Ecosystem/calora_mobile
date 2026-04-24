import 'package:freezed_annotation/freezed_annotation.dart';

part 'exercises_request.freezed.dart';
part 'exercises_request.g.dart';

enum ComputationType {
  @JsonValue('Duration')
  duration,
  @JsonValue('Count')
  count,
}

@freezed
abstract class ExercisesRequest with _$ExercisesRequest {
  const factory ExercisesRequest({
    required int id,
    required int workoutId,
    required String title,
    required String description,
    required List<ExerciseAsset> assets,
    required String duration,
    required bool isDone,
    required int order,
    ExerciseComputation? computation,
  }) = _ExercisesRequest;

  factory ExercisesRequest.fromJson(Map<String, dynamic> json) => _$ExercisesRequestFromJson(json);
}

@freezed
abstract class ExerciseAsset with _$ExerciseAsset {
  const factory ExerciseAsset({
    required String type,
    required String url,
  }) = _ExerciseAsset;

  factory ExerciseAsset.fromJson(Map<String, dynamic> json) => _$ExerciseAssetFromJson(json);
}

@freezed
abstract class ExerciseComputation with _$ExerciseComputation {
  const factory ExerciseComputation({
    int? id,
    String? activity,
    required ComputationType computationType,
    required double value,
  }) = _ExerciseComputation;

  factory ExerciseComputation.fromJson(Map<String, dynamic> json) =>
      _$ExerciseComputationFromJson(json);
}
