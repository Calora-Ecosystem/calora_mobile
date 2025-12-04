import 'package:freezed_annotation/freezed_annotation.dart';

part 'questions_request.freezed.dart';
part 'questions_request.g.dart';

@freezed
abstract class QuestionsRequest with _$QuestionsRequest {
  const factory QuestionsRequest({
    String? name,
    String? gender,
    List<int>? purposeIds,
    DateTime? birthDate,
    double? height,
    double? weight,
    double? bmi,
    double? targetWeight,
    String? activityHours,
    String? photo,
    String? language,
  }) = _QuestionsRequest;

  factory QuestionsRequest.fromJson(Map<String, dynamic> json) => _$QuestionsRequestFromJson(json);
}
