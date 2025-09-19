import 'package:calora/domain/model/profile/profile_request.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'main_profile_management.freezed.dart';

@freezed
abstract class MainProfileState with _$MainProfileState {
  const factory MainProfileState({
    @Default(ProfileRequest(name: '', email: '', bmi: 0, targetWeight: 0, weight: 0, userId: ''))
    ProfileRequest profile,
  }) = _MainProfileState;
}

@freezed
class MainProfileEffect with _$MainProfileEffect {
  const factory MainProfileEffect() = _MainProfileEffect;
}
