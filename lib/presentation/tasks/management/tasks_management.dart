import 'package:freezed_annotation/freezed_annotation.dart';

part 'tasks_management.freezed.dart';

@freezed
abstract class TasksState with _$TasksState {
  const factory TasksState({@Default(0) int levelIndex}) = _TasksState;
}

@freezed
class TasksEffect with _$TasksEffect {
  const factory TasksEffect() = _TasksEffect;
}
