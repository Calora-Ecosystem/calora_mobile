import 'package:freezed_annotation/freezed_annotation.dart';

part 'course_request.freezed.dart';
part 'course_request.g.dart';

@freezed
abstract class CourseRequest with _$CourseRequest {
  const factory CourseRequest({
    int? id,
    String? title,
    String? description,
    String? gender,
    String? type,
    int? total,
    int? order,
    List<Map<String, String>>? assets,
    int? price,
  }) = _CourseRequest;

  factory CourseRequest.fromJson(Map<String, dynamic> json) =>
      _$CourseRequestFromJson(json);
}
