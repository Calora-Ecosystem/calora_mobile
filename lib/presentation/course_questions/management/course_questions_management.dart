import 'package:calora/domain/model/questions/course_questions_info.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'course_questions_management.freezed.dart';

@freezed
abstract class CourseQuestionsState with _$CourseQuestionsState {
  const factory CourseQuestionsState({
    @Default(0) int currentIndex,
    @Default(CourseQuestionsInfo()) CourseQuestionsInfo courseQuestionsInfo,
  }) = _CourseQuestionsState;
}

@freezed
class CourseQuestionsEffect with _$CourseQuestionsEffect {
  const factory CourseQuestionsEffect() = _CourseQuestionsEffect;
}
