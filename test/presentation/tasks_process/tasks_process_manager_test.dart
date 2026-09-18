import 'dart:async';

import 'package:calora/domain/model/course/exercise/exercises_request.dart';
import 'package:calora/domain/repo/course/course_repo.dart';
import 'package:calora/presentation/tasks_process/management/tasks_process_management.dart';
import 'package:calora/presentation/tasks_process/management/tasks_process_manager.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCourseRepo implements CourseRepo {
  final calls = <String>[];
  final exerciseResponses = <int, List<Future<void> Function()>>{};
  Future<void> Function() workoutResponse = () async {};

  @override
  Future<void> finishedExercises(int id) {
    calls.add('exercise:$id');
    final responses = exerciseResponses[id];
    if (responses == null || responses.isEmpty) return Future.value();
    return responses.removeAt(0)();
  }

  @override
  Future<void> finishWorkout(int id) {
    calls.add('workout:$id');
    return workoutResponse();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ExercisesRequest _exercise(int id, {double minutes = 0}) => ExercisesRequest(
  id: id,
  workoutId: 52,
  title: 'Exercise $id',
  description: '',
  assets: const [],
  duration: '00:00:00',
  isDone: false,
  order: id,
  computation: ExerciseComputation(
    computationType: ComputationType.duration,
    value: minutes,
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeCourseRepo repo;
  late TasksProcessManager manager;

  setUp(() {
    repo = _FakeCourseRepo();
    manager = TasksProcessManager(repo);
  });

  tearDown(() => manager.close());

  test(
    'submits the workout only after the last exercise is recorded',
    () async {
      final lastExercise = Completer<void>();
      repo.exerciseResponses[2] = [() => lastExercise.future];

      manager.init([_exercise(1), _exercise(2)], workoutId: 52);
      await pumpEventQueue();

      expect(repo.calls, ['exercise:1', 'exercise:2']);

      lastExercise.complete();
      await pumpEventQueue();

      expect(repo.calls, ['exercise:1', 'exercise:2', 'workout:52']);
    },
  );

  test(
    'retries exercises that failed to record before submitting the workout',
    () async {
      repo.exerciseResponses[1] = [() => Future.error(Exception('offline'))];

      manager.init([_exercise(1), _exercise(2)], workoutId: 52);
      await pumpEventQueue();

      expect(repo.calls, [
        'exercise:1',
        'exercise:2',
        'exercise:1',
        'workout:52',
      ]);
    },
  );

  test(
    'a rejected workout submission does not escape as an unhandled error',
    () async {
      repo.workoutResponse = () => Future.error(Exception('400'));

      manager.init([_exercise(1)], workoutId: 52);
      await pumpEventQueue();

      expect(repo.calls, ['exercise:1', 'workout:52']);
    },
  );

  test(
    'completes the workout once when next is tapped after the end',
    () async {
      final effects = <TasksProcessEffect>[];
      manager.effectSubject.listen(effects.add);

      manager.init([_exercise(1)], workoutId: 52);
      manager.next();
      await pumpEventQueue();

      expect(effects, hasLength(1));
      expect(repo.calls, ['exercise:1', 'workout:52']);
    },
  );

  test('pauses when the app leaves the foreground', () {
    manager.init([_exercise(1, minutes: 1)], workoutId: 52);
    expect(manager.state.isPaused, isFalse);

    manager.didChangeAppLifecycleState(AppLifecycleState.hidden);

    expect(manager.state.isPaused, isTrue);
  });
}
