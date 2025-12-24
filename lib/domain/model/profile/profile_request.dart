import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_request.freezed.dart';
part 'profile_request.g.dart';

@freezed
abstract class ProfileRequest with _$ProfileRequest {
  const factory ProfileRequest({
    @JsonKey(name: 'entryWeight') double? entryWeight,
    @JsonKey(name: 'name') String? name,
    @JsonKey(name: 'birthDate') String? birthDay,
    @JsonKey(name: 'goal') String? goal,
    @JsonKey(name: 'activityLevel') dynamic activityLevel,
    @JsonKey(name: 'metrics') String? metrics,
    @JsonKey(name: 'email') String? email,
    @JsonKey(name: 'bmi') double? bmi,
    @JsonKey(name: 'gender') String? gender,
    @JsonKey(name: 'height') double? height,
    @JsonKey(name: 'targetWeight') double? targetWeight,
    @JsonKey(name: 'weight') double? weight,
    @JsonKey(name: 'userId') int? userId,
    @JsonKey(name: 'photo') String? photo,
  }) = _ProfileRequest;

  factory ProfileRequest.fromJson(Map<String, dynamic> json) => _$ProfileRequestFromJson(json);
}
