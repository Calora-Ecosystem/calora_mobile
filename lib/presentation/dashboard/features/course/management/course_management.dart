import 'package:calora/common/base/profile_store.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'course_management.freezed.dart';

@freezed
abstract class CourseState with _$CourseState {
  const factory CourseState({@Default(Gender.Female) Gender gender}) = _CourseState;
}

@freezed
class CourseEffect with _$CourseEffect {
  const factory CourseEffect() = _CourseEffect;
}
