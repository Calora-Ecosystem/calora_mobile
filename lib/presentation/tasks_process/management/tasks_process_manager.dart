import 'dart:async';

import 'package:calora/common/extensions/duration.dart';
import 'package:calora/domain/model/course/exercise/exercises_request.dart';
import 'package:calora/domain/repo/course/course_repo.dart';
import 'package:calora/presentation/tasks_process/management/tasks_process_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class TasksProcessManager extends Manager<TasksProcessState, TasksProcessEffect> {
  Timer? _timer;
  CourseRepo _courseRepo;

  bool _leaveSheetOpen = false;

  TasksProcessManager(this._courseRepo) : super(const TasksProcessState());
  int? _workoutId;

  void init(List<ExercisesRequest> exercises, {required int workoutId}) {
    if (exercises.isEmpty) return;

    _workoutId = workoutId;

    emit(state.copyWith(exercises: exercises, currentIndex: 0));
    _startForCurrent();
    emit(state.copyWith(isInitialized: true));
  }

  void finishWorkout(int id) {
    _courseRepo
        .finishWorkout(id)
        .handle(
          onStart: () => emit(state.copyWith()),
          onDone: () => emit(state.copyWith()),
          onError: (e) => emit(state.copyWith()),
        );
  }

  ExercisesRequest? get currentExercise {
    if (state.exercises.isEmpty) return null;
    return state.exercises[state.currentIndex];
  }

  void togglePause() {
    emit(state.copyWith(isPaused: !state.isPaused));
  }

  void onExerciseFinished() {
    final ex = currentExercise;
    if (ex == null) return;

    unawaited(finishExercises(ex.id));

    final newCompletedExercises = List<ExercisesRequest>.from(state.completedExercises)..add(ex);

    emit(
      state.copyWith(
        completedTaskCount: state.completedTaskCount + 1,
        completedExercises: newCompletedExercises,
      ),
    );

    _goNextIndex();
  }

  void next() {
    _timer?.cancel();
    _goNextIndex();
  }

  void _goNextIndex() {
    final lastIndex = state.exercises.length - 1;

    if (state.currentIndex < lastIndex) {
      emit(state.copyWith(currentIndex: state.currentIndex + 1));
      _startForCurrent();
      return;
    }
    final finishedAll = state.completedTaskCount == state.exercises.length;
    final id = _workoutId;
    if (finishedAll && id != null) {
      unawaited(_courseRepo.finishWorkout(id));
    }
    publish(
      TasksProcessEffect.navigateFinish(
        calories: 500,
        day: 1,
        durationSeconds: _totalWorkoutDurationSeconds(state.completedExercises),
        taskCount: state.completedTaskCount,
      ),
    );
  }

  void previous() {
    if (state.currentIndex <= 0) return;

    _timer?.cancel();
    emit(state.copyWith(currentIndex: state.currentIndex - 1));
    _startForCurrent();
  }

  void requestLeave() {
    if (_leaveSheetOpen) return;
    _leaveSheetOpen = true;
    emit(state.copyWith(isPaused: true));
    publish(const TasksProcessEffect.showLeaveSheet());
  }

  void leaveSheetClosed() {
    _leaveSheetOpen = false;
    emit(state.copyWith(isPaused: false));
  }

  void _startForCurrent() {
    _timer?.cancel();
    final ex = currentExercise;
    if (ex == null) return;

    final total = parseDuration(ex.duration).inSeconds;

    if (total <= 0) {
      emit(
        state.copyWith(
          totalSeconds: 0,
          remainingSeconds: 0,
          isPaused: false,
        ),
      );

      onExerciseFinished();
      return;
    }

    emit(
      state.copyWith(
        totalSeconds: total,
        remainingSeconds: total,
        isPaused: false,
      ),
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (state.isPaused) return;

      if (state.remainingSeconds <= 1) {
        t.cancel();
        emit(state.copyWith(remainingSeconds: 0));
        onExerciseFinished();
      } else {
        emit(state.copyWith(remainingSeconds: state.remainingSeconds - 1));
      }
    });
  }

  int _totalWorkoutDurationSeconds(List<ExercisesRequest> list) {
    var sum = 0;
    for (final e in list) {
      sum += parseDuration(e.duration).inSeconds;
    }
    return sum;
  }

  Future<void> finishExercises(int id) async {
    await _courseRepo
        .finishedExercises(id)
        .handle(
          onStart: () => emit(state.copyWith(isFinished: true)),
          onDone: () => emit(state.copyWith(isFinished: false)),
          onError: (e) => emit(state.copyWith(isFinished: false)),
        );
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
