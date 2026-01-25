import 'package:calora/domain/repo/course/course_repo.dart';
import 'package:calora/presentation/tasks/management/tasks_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class TasksManager extends Manager<TasksState, TasksEffect> {
  final CourseRepo _courseRepo;

  TasksManager(this._courseRepo) : super(const TasksState());

  void getExercises(int id) {
    _courseRepo
        .getExercisesByWorkoutId(id)
        .handle(
          onStart: () => emit(
            state.copyWith(isLoading: true),
          ),
          onData: (data) => emit(state.copyWith(exercises: data, isLoading: false)),
          onError: (error) => emit(state.copyWith(isLoading: false)),
        );
  }
}
