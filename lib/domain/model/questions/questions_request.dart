import 'package:freezed_annotation/freezed_annotation.dart';

part 'questions_request.freezed.dart';
part 'questions_request.g.dart';

enum Purpose { WeightLoss, SaveCurrent, MuscleDevelopment }

@freezed
abstract class QuestionsRequest with _$QuestionsRequest {
  const factory QuestionsRequest({
    String? name,
    String? gender,
    String? purpose,
    DateTime? birthDate,
    double? height,
    double? weight,
    double? bmi,
    double? targetWeight,
    String? activityLevel,
    String? photo,
    String? language,
  }) = _QuestionsRequest;

  factory QuestionsRequest.fromJson(Map<String, dynamic> json) => _$QuestionsRequestFromJson(json);
}
