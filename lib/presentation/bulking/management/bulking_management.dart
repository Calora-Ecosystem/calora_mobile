import 'package:calora/domain/model/course/video_course_info.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'bulking_management.freezed.dart';

@freezed
abstract class BulkingState with _$BulkingState {
  factory BulkingState({CoursesInfo? videoCourse, @Default(false) bool isLoading}) = _BulkingState;
}

@freezed
class BulkingEffect with _$BulkingEffect {
  const factory BulkingEffect() = _BulkingEffect;
}
