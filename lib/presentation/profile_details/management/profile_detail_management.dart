import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_detail_management.freezed.dart';

@freezed
abstract class ProfileDetailState with _$ProfileDetailState {
  const factory ProfileDetailState({
    @Default(false) bool isAppleHealthSelected,
    @Default(false) bool isSamsungHealthSelected,
    @Default(false) bool isGarminSelected,
    @Default(false) bool isGoogleFitSelected,
    @Default(false) bool isDeletingAccount,
  }) = _ProfileDetailState;
}

@freezed
class ProfileDetailEffect with _$ProfileDetailEffect {
  const factory ProfileDetailEffect.showDialog() = ShowDialog;
  const factory ProfileDetailEffect.showDeleteAccountDialog() =
      ShowDeleteAccountDialog;
  const factory ProfileDetailEffect.accountDeleted() = AccountDeleted;
  const factory ProfileDetailEffect.deleteAccountFailed() = DeleteAccountFailed;
}
