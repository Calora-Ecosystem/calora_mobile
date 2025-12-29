import 'package:calora/domain/repo/course/course_repo.dart';
import 'package:calora/presentation/dashboard/features/course/management/course_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class CourseManager extends Manager<CourseState, CourseEffect> {
  final CourseRepo _courseRepo;

  CourseManager(this._courseRepo) : super(const CourseState());

  void getCourses() => _courseRepo.getCourse().handle(
    onStart: () {
      emit(state.copyWith(isLoading: true));
    },
    onData: (data) {
      emit(state.copyWith(courses: data, isLoading: false));
    },
    onError: (error) {
      emit(state.copyWith(isLoading: false));
    },
  );
}
