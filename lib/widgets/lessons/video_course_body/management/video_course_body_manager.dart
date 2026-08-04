import 'package:calora/domain/model/lesson/lesson_request.dart';
import 'package:calora/domain/repo/course/course_repo.dart';
import 'package:calora/widgets/lessons/video_course_body/management/video_course_body_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

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
          onError: (error) {
            emit(state.copyWith(isLoading: false));
            publish(VideoCourseBodyEffect.showError(error.toString()));
          },
        );
  }

  void videoCompleted(int lessonId) {
    _courseRepo
        .updateVideoCourseFinished(lessonId)
        .handle(
          onStart: () {},
          // Mark the lesson finished ONLY when the request actually succeeds.
          // handle()'s `onDone` runs in a `finally` (fires on error too), so
          // doing this there would optimistically unlock the next lesson even
          // when the backend never recorded completion — leaving local state
          // out of sync with the server after a refetch.
          onData: (_) {
            final updated = state.lessons.map((l) {
              if (l.id == lessonId) return l.copyWith(isFinished: true);
              return l;
            }).toList();
            emit(state.copyWith(lessons: updated));
          },
          onError: (error) {
            publish(VideoCourseBodyEffect.showError(error.toString()));
          },
        );
  }

  void onVideoTapped(LessonRequest lesson, int index) {
    if (index > 0) {
      final prev = state.lessons[index - 1];
      if (prev.isFinished != true) {
        publish(const VideoCourseBodyEffect.showNeedFinishPrevious());
        return;
      }
    }

    if (lesson.isFree || state.isPurchased) {
      publish(VideoCourseBodyEffect.openVideo(lesson, index));
    }
  }

  void setPurchased(bool value) {
    emit(state.copyWith(isPurchased: value));
  }
}
