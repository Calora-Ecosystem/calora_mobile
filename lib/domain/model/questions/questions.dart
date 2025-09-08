import 'package:freezed_annotation/freezed_annotation.dart';

part 'questions.freezed.dart';
part 'questions.g.dart';

@freezed
abstract class Questions with _$Questions {
  const factory Questions({
    String? name,
    String? gender,
    List<int>? purposeIds,
    DateTime? birthDate,
    double? height,
    double? weight,
    double? targetWeight,
    String? activityHours,
  }) = _Questions;

  factory Questions.fromJson(Map<String, dynamic> json) => _$QuestionsFromJson(json);
}
