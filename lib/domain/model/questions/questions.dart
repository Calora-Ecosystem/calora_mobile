import 'package:calora/common/base/profile_store.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'questions.freezed.dart';
part 'questions.g.dart';

enum ActivityLevel { Minimal, Less, Medium, High, Maximal }

@freezed
abstract class Questions with _$Questions {
  const factory Questions({
    String? name,
    Gender? gender,
    double? entryWeight,
    List<int>? purposeIds,
    DateTime? birthDate,
    double? height,
    double? weight,
    double? targetWeight,
    String? activityHours,
  }) = _Questions;

  factory Questions.fromJson(Map<String, dynamic> json) => _$QuestionsFromJson(json);
}
