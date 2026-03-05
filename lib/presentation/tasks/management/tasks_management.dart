import 'package:calora/domain/model/course/exercise/exercises_request.dart';
import 'package:calora/domain/model/workout/workout_request.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tasks_management.freezed.dart';

@freezed
abstract class TasksState with _$TasksState {
  const factory TasksState({
    @Default(0) int levelIndex,
    @Default([]) List<ExercisesRequest> exercises,
    @Default(0) int currentTaskIndex,
    @Default(false) bool isLoading,
    WorkoutRequest? workout,
  }) = _TasksState;
}

@freezed
class TasksEffect with _$TasksEffect {
  const factory TasksEffect.onLevelChanged() = _OnLevelChanged;
}
