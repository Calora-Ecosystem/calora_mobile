import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_detail_management.freezed.dart';

@freezed
abstract class ProfileDetailState with _$ProfileDetailState {
  const factory ProfileDetailState({
    @Default(false) bool isAppleHealthSelected,
    @Default(false) bool isSamsungHealthSelected,
    @Default(false) bool isGarminSelected,
    @Default(false) bool isGoogleFitSelected,
  }) = _ProfileDetailState;
}

@freezed
class ProfileDetailEffect with _$ProfileDetailEffect {
  const factory ProfileDetailEffect.showDialog() = ShowDialog;
}
