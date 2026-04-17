import 'package:calora/domain/model/lesson/lesson_info.dart';
import 'package:calora/domain/model/workout/workout_request.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'lessons_management.freezed.dart';

@freezed
abstract class LessonsState with _$LessonsState {
  const factory LessonsState({
    @Default(0) int levelIndex,
    @Default('') String level,
    @Default(false) bool isLoading,
    @Default([]) List<LessonInfo> lessons,
    @Default([]) List<WorkoutRequest> workouts,
  }) = _LessonsState;
}

@freezed
class LessonsEffect with _$LessonsEffect {
  const factory LessonsEffect.empty() = _Empty;

  const factory LessonsEffect.showError(String message) = _ShowError;
}
