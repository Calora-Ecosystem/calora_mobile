import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_management.freezed.dart';

@freezed
abstract class ProfileState with _$ProfileState {
  const factory ProfileState({
    @Default(false) bool isAppleHealthSelected,
    @Default(false) bool isSamsungHealthSelected,
    @Default(false) bool isGarminSelected,
    @Default(false) bool isGoogleFitSelected,
  }) = _ProfileState;
}

@freezed
class ProfileEffect with _$ProfileEffect {
  const factory ProfileEffect.showDialog() = ShowDialog;
}
