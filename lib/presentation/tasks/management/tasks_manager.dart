import 'package:calora/domain/model/lesson/lesson_info.dart';
import 'package:calora/presentation/tasks/management/tasks_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class TasksManager extends Manager<TasksState, TasksEffect> {
  TasksManager() : super(const TasksState());

  void setLevel(int index) {
    emit(state.copyWith(levelIndex: index));
  }

  void initTasks(List<TaskInfo> tasks) {
    emit(state.copyWith(tasks: tasks, currentTaskIndex: 0));
  }

  void nextTask() {
    if (state.currentTaskIndex < state.tasks.length - 1) {
      emit(state.copyWith(currentTaskIndex: state.currentTaskIndex + 1));
    }
  }

  void previousTask() {
    if (state.currentTaskIndex > 0) {
      emit(state.copyWith(currentTaskIndex: state.currentTaskIndex - 1));
    }
  }

  void completeCurrentTask() {
    final updatedTasks = List<TaskInfo>.from(state.tasks);
    final currentTask = updatedTasks[state.currentTaskIndex];

    updatedTasks[state.currentTaskIndex] = currentTask.copyWith(isCompleted: true);

    emit(state.copyWith(tasks: updatedTasks));
  }

  TaskInfo? get currentTask {
    if (state.tasks.isEmpty) return null;
    return state.tasks[state.currentTaskIndex];
  }
}
