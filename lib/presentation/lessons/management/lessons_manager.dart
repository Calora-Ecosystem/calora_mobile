import 'package:calora/domain/repo/course/course_repo.dart';
import 'package:calora/presentation/lessons/management/lessons_management.dart';
import 'package:injectable/injectable.dart' show injectable;
import 'package:management/management.dart';

@injectable
class LessonsManager extends Manager<LessonsState, LessonsEffect> {
  final CourseRepo _courseRepo;

  LessonsManager(this._courseRepo) : super(const LessonsState());

  void setLevel(int index) {
    emit(state.copyWith(levelIndex: index));
  }

  void getWorkout() {
    _courseRepo.getWorkout().handle(
      onStart: () => emit(state.copyWith(isLoading: true)),
      onData: (workouts) =>
          emit(state.copyWith(workouts: workouts, isLoading: false)),
      onError: (error) => emit(state.copyWith(isLoading: false)),
    );
  }
}
