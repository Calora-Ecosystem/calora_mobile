import 'package:calora/domain/model/lesson/lesson_request.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:calora/domain/model/course/course_request.dart';

part 'course_management.freezed.dart';

@freezed
abstract class CourseState with _$CourseState {
  const factory CourseState({
    @Default([]) List<CourseRequest> courses,
    @Default(false) bool isLoading,
    @Default([]) List<LessonRequest> lessons,
  }) = _CourseState;
}

@freezed
abstract class CourseEffect with _$CourseEffect {
  const factory CourseEffect.navigateToLessons({
    required CourseRequest course,
    required List<LessonRequest> lessons,
  }) = _NavigateToLessons;
}
