// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_request.freezed.dart';
part 'profile_request.g.dart';

@freezed
abstract class ProfileRequest with _$ProfileRequest {
  const ProfileRequest._();

  const factory ProfileRequest({
    @JsonKey(name: 'entryWeight') double? entryWeight,
    @JsonKey(name: 'name') String? name,
    @JsonKey(name: 'birthDate') String? birthDay,
    @JsonKey(name: 'purpose') String? goal,
    @JsonKey(name: 'activityLevel') String? activityLevel,
    @JsonKey(name: 'email') String? email,
    @JsonKey(name: 'bmi') double? bmi,
    @JsonKey(name: 'gender') String? gender,
    @JsonKey(name: 'height') double? height,
    @JsonKey(name: 'targetWeight') double? targetWeight,
    @JsonKey(name: 'weight') double? weight,
    @JsonKey(name: 'userId') int? userId,
    @JsonKey(name: 'photo') String? photo,
    @JsonKey(name: 'physicalActivity') String? physicalActivity,
    @JsonKey(name: 'language') String? language,
    @JsonKey(name: 'progress') List<MetricProgress>? progress,
  }) = _ProfileRequest;

  factory ProfileRequest.fromJson(Map<String, dynamic> json) =>
      _$ProfileRequestFromJson(json);

  /// Looks up the target value for a metric inside the new `progress[]`
  /// payload (case-insensitive match on `metric`).
  double? targetForMetric(String metric) {
    final list = progress;
    if (list == null) return null;
    final lower = metric.toLowerCase();
    for (final entry in list) {
      if (entry.metric?.toLowerCase() == lower) return entry.target;
    }
    return null;
  }

  /// Looks up the current progress value for a metric inside `progress[]`.
  double? progressForMetric(String metric) {
    final list = progress;
    if (list == null) return null;
    final lower = metric.toLowerCase();
    for (final entry in list) {
      if (entry.metric?.toLowerCase() == lower) return entry.progress;
    }
    return null;
  }
}

@freezed
abstract class MetricProgress with _$MetricProgress {
  const factory MetricProgress({
    @JsonKey(name: 'target') double? target,
    @JsonKey(name: 'progress') double? progress,
    @JsonKey(name: 'metric') String? metric,
  }) = _MetricProgress;

  factory MetricProgress.fromJson(Map<String, dynamic> json) =>
      _$MetricProgressFromJson(json);
}
