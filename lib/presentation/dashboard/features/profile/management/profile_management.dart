import 'package:calora/domain/model/profile/profile_request.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_management.freezed.dart';

@freezed
abstract class ProfileState with _$ProfileState {
  const factory ProfileState({
    ProfileRequest? profile,
    @Default(false) bool isLoading,
    @Default(true) bool showBmiProgress,
  }) = _ProfileState;
}

@freezed
class ProfileEffect with _$ProfileEffect {
  const factory ProfileEffect() = _ProfileEffect;
}
