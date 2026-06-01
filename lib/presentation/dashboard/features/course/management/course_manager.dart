import 'dart:async';

import 'package:calora/common/service/course_tab_signal.dart';
import 'package:calora/domain/repo/course/course_repo.dart';
import 'package:calora/presentation/dashboard/features/course/management/course_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class CourseManager extends Manager<CourseState, CourseEffect> {
  final CourseRepo _courseRepo;
  final CourseTabSignal _courseTabSignal;

  StreamSubscription<void>? _tapSub;

  CourseManager(this._courseRepo, this._courseTabSignal)
      : super(const CourseState()) {
    _tapSub = _courseTabSignal.stream.listen((_) => getCourses());
  }

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

  @override
  Future<void> close() async {
    await _tapSub?.cancel();
    return super.close();
  }
}
