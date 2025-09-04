import 'package:freezed_annotation/freezed_annotation.dart';

part 'course_management.freezed.dart';

@freezed
abstract class CourseState with _$CourseState {
  const factory CourseState() = _CourseState;
}

@freezed
class CourseEffect with _$CourseEffect {
  const factory CourseEffect() = _CourseEffect;
}
