import 'package:calora/domain/model/lesson/lesson_request.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'video_course_body_management.freezed.dart';

@freezed
abstract class VideoCourseBodyState with _$VideoCourseBodyState {
  const factory VideoCourseBodyState({
    @Default([]) List<LessonRequest> lessons,
    @Default(false) bool isLoading,
    @Default(false) bool isPurchased,
  }) = _VideoCourseBodyState;
}

@freezed
abstract class VideoCourseBodyEffect with _$VideoCourseBodyEffect {
  const factory VideoCourseBodyEffect.openInfoSheet(String description) = _OpenInfoSheet;

  const factory VideoCourseBodyEffect.openVideo(
    LessonRequest lesson,
    int index,
  ) = _OpenVideo;

  const factory VideoCourseBodyEffect.showNeedFinishPrevious() = _ShowNeedFinishPrevious;
}
