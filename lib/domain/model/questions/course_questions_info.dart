import 'package:freezed_annotation/freezed_annotation.dart';

part 'course_questions_info.freezed.dart';
part 'course_questions_info.g.dart';

@freezed
abstract class CourseQuestionsInfo with _$CourseQuestionsInfo {
  const factory CourseQuestionsInfo({
    int? condition,
    int? activityTime,
    String? trainingTime,
  }) = _CourseQuestionsInfo;

  factory CourseQuestionsInfo.fromJson(Map<String, dynamic> json) =>
      _$CourseQuestionsInfoFromJson(json);
}
