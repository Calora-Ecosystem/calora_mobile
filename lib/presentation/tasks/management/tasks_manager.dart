import 'package:calora/presentation/tasks/management/tasks_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class TasksManager extends Manager<TasksState, TasksEffect> {
  TasksManager() : super(const TasksState());

  void setLevel(int index) {
    emit(state.copyWith(levelIndex: index));
  }
}
