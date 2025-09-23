import 'package:calora/domain/model/profile/profile_request.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_management.freezed.dart';

@freezed
abstract class ProfileState with _$ProfileState {
  const factory ProfileState({
    @Default(
      ProfileRequest(
        name: '',
        email: '',
        height: 0,
        bmi: 0,
        targetWeight: 0,
        weight: 0,
        userId: '',
        gender: '',
        birthDay: '',
        goal: '',
        activityLevel: '',
        metrics: '',
      ),
    )
    ProfileRequest profile,
  }) = _ProfileState;
}

@freezed
class ProfileEffect with _$ProfileEffect {
  const factory ProfileEffect() = _ProfileEffect;
}
