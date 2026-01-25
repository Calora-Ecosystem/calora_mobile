import 'package:calora/domain/model/course/exercise/exercises_request.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tasks_process_management.freezed.dart';

@freezed
abstract class TasksProcessState with _$TasksProcessState {
  const factory TasksProcessState({
    @Default([]) List<ExercisesRequest> exercises,
    @Default(0) int currentIndex,
    @Default(0) int totalSeconds,
    @Default(0) int remainingSeconds,
    @Default(false) bool isPaused,
    @Default(false) bool isInitialized,
    @Default(false) bool isFinished,
    @Default(0) int completedTaskCount,
    @Default([]) List<ExercisesRequest> completedExercises,
  }) = _TasksProcessState;
}

@freezed
class TasksProcessEffect with _$TasksProcessEffect {
  const factory TasksProcessEffect.showLeaveSheet() = _ShowLeaveSheet;

  const factory TasksProcessEffect.navigateFinish({
    required int calories,
    required int day,
    required int durationSeconds,
    required int taskCount,
  }) = _NavigateFinish;
}
