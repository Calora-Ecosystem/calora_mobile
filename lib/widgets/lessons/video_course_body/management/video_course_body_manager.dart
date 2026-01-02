import 'package:calora/domain/model/lesson/lesson_request.dart';
import 'package:calora/domain/repo/course/course_repo.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

import 'video_course_body_management.dart';

@injectable
class VideoCourseBodyManager extends Manager<VideoCourseBodyState, VideoCourseBodyEffect> {
  final CourseRepo _courseRepo;

  VideoCourseBodyManager(this._courseRepo) : super(const VideoCourseBodyState());

  void getVideoCourse(int id) {
    _courseRepo
        .getLessonsById(id)
        .handle(
          onStart: () => emit(state.copyWith(isLoading: true)),
          onData: (data) => emit(state.copyWith(lessons: data, isLoading: false)),
          onError: (error) => emit(state.copyWith(isLoading: false)),
        );
  }

  void videoCompleted(int id) {
    _courseRepo
        .updateVideoCourseFinished(id)
        .handle(
          onStart: () => emit(state.copyWith(isLoading: true)),
          onDone: () => emit(state.copyWith(isLoading: false)),
          onError: (e) => emit(state.copyWith(isLoading: false)),
        );
  }

  void onVideoTapped(LessonRequest lesson, int index) {
    if (lesson.isFree || state.isPurchased) {
      publish(VideoCourseBodyEffect.openVideo(lesson, index));
    }
  }
}
