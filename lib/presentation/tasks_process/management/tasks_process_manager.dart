import 'dart:async';

import 'package:calora/common/extensions/duration.dart';
import 'package:calora/domain/model/course/exercise/exercises_request.dart';
import 'package:calora/domain/repo/course/course_repo.dart';
import 'package:calora/presentation/tasks_process/management/tasks_process_management.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

@injectable
class TasksProcessManager extends Manager<TasksProcessState, TasksProcessEffect>
    with WidgetsBindingObserver {
  static const _countTickSeconds = 3;

  final CourseRepo _courseRepo;
  final _exerciseSyncs = <int, Future<bool>>{};

  Timer? _timer;
  int? _workoutId;
  bool _leaveSheetOpen = false;
  bool _completed = false;

  TasksProcessManager(this._courseRepo) : super(const TasksProcessState()) {
    WidgetsBinding.instance.addObserver(this);
  }

  void init(List<ExercisesRequest> exercises, {required int workoutId}) {
    if (exercises.isEmpty) return;

    _workoutId = workoutId;
    unawaited(WakelockPlus.enable().handle());

    emit(state.copyWith(exercises: exercises, currentIndex: 0));
    _startForCurrent();
    emit(state.copyWith(isInitialized: true));
  }

  ExercisesRequest? get currentExercise {
    if (state.exercises.isEmpty) return null;
    return state.exercises[state.currentIndex];
  }

  double get progress {
    if (state.totalSeconds <= 0) return 0;
    return 1 - state.remainingSeconds / state.totalSeconds;
  }

  Duration get tick =>
      Duration(seconds: state.isCountType ? _countTickSeconds : 1);

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.hidden ||
        lifecycleState == AppLifecycleState.paused) {
      emit(state.copyWith(isPaused: true));
    }
  }

  void togglePause() {
    emit(state.copyWith(isPaused: !state.isPaused));
  }

  void onExerciseFinished() {
    final ex = currentExercise;
    if (ex == null || _completed) return;

    _exerciseSyncs[ex.id] = _syncExercise(ex.id);

    final newCompletedExercises = List<ExercisesRequest>.from(
      state.completedExercises,
    )..add(ex);

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
    onExerciseFinished();
  }

  void _goNextIndex() {
    final lastIndex = state.exercises.length - 1;

    if (state.currentIndex < lastIndex) {
      emit(state.copyWith(currentIndex: state.currentIndex + 1));
      _startForCurrent();
      return;
    }

    _completed = true;
    unawaited(WakelockPlus.disable().handle());

    final id = _workoutId;
    if (id != null) {
      unawaited(_submitWorkout(id).handle());
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

    // `computation.value` is authoritative for both types:
    //   Count    → number of reps, tick every 3s
    //   Duration → number of MINUTES (per backend contract); converted
    //              to seconds here because `_startDurationCountdown`
    //              ticks every 1s.
    // The legacy `duration` string is only used as a fallback when
    // `computation` is missing (older exercises).
    final comp = ex.computation;
    if (comp == null) {
      _startDurationCountdown(parseDuration(ex.duration).inSeconds);
      return;
    }

    final value = comp.value.toInt();
    if (comp.computationType == ComputationType.count) {
      _startCountCountdown(value);
    } else {
      _startDurationCountdown(value * 60);
    }
  }

  void _startDurationCountdown(int total) {
    if (total <= 0) {
      emit(
        state.copyWith(
          isCountType: false,
          totalSeconds: 0,
          remainingSeconds: 0,
          totalCount: 0,
          remainingCount: 0,
          isPaused: false,
        ),
      );
      onExerciseFinished();
      return;
    }

    emit(
      state.copyWith(
        isCountType: false,
        totalSeconds: total,
        remainingSeconds: total,
        totalCount: 0,
        remainingCount: 0,
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

  /// Count-type exercise: the provided value (e.g. 10) decrements by 1 every
  /// 3 seconds until it reaches 0, then the exercise auto-advances.
  /// totalSeconds/remainingSeconds are kept in sync so the ProgressButton
  /// animation fills over the full count duration.
  void _startCountCountdown(int count) {
    if (count <= 0) {
      emit(
        state.copyWith(
          isCountType: true,
          totalSeconds: 0,
          remainingSeconds: 0,
          totalCount: 0,
          remainingCount: 0,
          isPaused: false,
        ),
      );
      onExerciseFinished();
      return;
    }

    final total = count * _countTickSeconds;

    emit(
      state.copyWith(
        isCountType: true,
        totalSeconds: total,
        remainingSeconds: total,
        totalCount: count,
        remainingCount: count,
        isPaused: false,
      ),
    );

    _timer = Timer.periodic(const Duration(seconds: _countTickSeconds), (t) {
      if (state.isPaused) return;

      final nextRemaining = state.remainingCount - 1;
      if (nextRemaining <= 0) {
        t.cancel();
        emit(state.copyWith(remainingCount: 0, remainingSeconds: 0));
        onExerciseFinished();
      } else {
        emit(
          state.copyWith(
            remainingCount: nextRemaining,
            remainingSeconds: nextRemaining * _countTickSeconds,
          ),
        );
      }
    });
  }

  int _totalWorkoutDurationSeconds(List<ExercisesRequest> list) {
    var sum = 0;
    for (final e in list) {
      final comp = e.computation;
      if (comp == null) {
        sum += parseDuration(e.duration).inSeconds;
      } else if (comp.computationType == ComputationType.count) {
        sum += comp.value.toInt() * _countTickSeconds;
      } else {
        sum += comp.value.toInt();
      }
    }
    return sum;
  }

  Future<bool> _syncExercise(int id) async {
    try {
      await _courseRepo.finishedExercises(id);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _submitWorkout(int workoutId) async {
    final unsynced = [
      for (final MapEntry(key: id, value: synced) in _exerciseSyncs.entries)
        if (!await synced) id,
    ];
    await Future.wait(unsynced.map(_syncExercise));
    await _courseRepo.finishWorkout(workoutId);
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    unawaited(WakelockPlus.disable().handle());
    return super.close();
  }
}
