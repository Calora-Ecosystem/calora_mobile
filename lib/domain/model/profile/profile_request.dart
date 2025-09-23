import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_request.freezed.dart';
part 'profile_request.g.dart';

@freezed
abstract class ProfileRequest with _$ProfileRequest {
  const factory ProfileRequest({
    required String name,
    required String birthDay,
    required String goal,
    required String activityLevel,
    required String metrics,
    required String email,
    required double bmi,
    required String gender,
    required double height,
    required double targetWeight,
    required double weight,
    required String userId,
  }) = _ProfileRequest;

  factory ProfileRequest.fromJson(Map<String, dynamic> json) => _$ProfileRequestFromJson(json);
}
