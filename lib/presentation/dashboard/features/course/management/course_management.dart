import 'package:calora/domain/model/profile/profile.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'course_management.freezed.dart';

@freezed
abstract class CourseState with _$CourseState {
  const factory CourseState({@Default(Gender.female) Gender gender}) = _CourseState;
}

@freezed
class CourseEffect with _$CourseEffect {
  const factory CourseEffect() = _CourseEffect;
}
