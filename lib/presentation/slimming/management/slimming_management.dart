import 'package:calora/domain/model/course/video_course_info.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'slimming_management.freezed.dart';

@freezed
abstract class SlimmingState with _$SlimmingState {
  const factory SlimmingState({
    @Default([]) List<VideoCourseInfo> videoCourses,
    @Default(false) bool isLoading,
  }) = _SlimmingState;
}

@freezed
class SlimmingEffect with _$SlimmingEffect {
  const factory SlimmingEffect() = _SlimmingEffect;
}
