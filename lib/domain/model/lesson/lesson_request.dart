import 'package:freezed_annotation/freezed_annotation.dart';

part 'lesson_request.freezed.dart';
part 'lesson_request.g.dart';

@freezed
abstract class LessonRequest with _$LessonRequest {
  const factory LessonRequest({
    required int id,
    required int courseId,
    required String duration,
    required bool isFree,
    required String title,
    required String description,
    required int order,
    required bool isFinished,
    required List<LessonAsset> assets,
  }) = _LessonRequest;

  factory LessonRequest.fromJson(Map<String, dynamic> json) => _$LessonRequestFromJson(json);
}

@freezed
abstract class LessonAsset with _$LessonAsset {
  const factory LessonAsset({required String type, required String url}) = _LessonAsset;

  factory LessonAsset.fromJson(Map<String, dynamic> json) => _$LessonAssetFromJson(json);
}
