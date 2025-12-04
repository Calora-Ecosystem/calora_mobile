import 'package:calora/domain/model/lesson/lesson_info.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'lessons_management.freezed.dart';

@freezed
abstract class LessonsState with _$LessonsState {
  const factory LessonsState({@Default(0) int levelIndex, @Default([]) List<LessonInfo> lessons}) =
      _LessonsState;
}

@freezed
class LessonsEffect with _$LessonsEffect {
  const factory LessonsEffect() = _LessonsEffect;
}
