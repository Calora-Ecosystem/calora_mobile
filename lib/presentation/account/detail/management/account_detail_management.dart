import 'package:calora/domain/model/profile/profile.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_detail_management.freezed.dart';

@freezed
abstract class AccountDetailState with _$AccountDetailState {
  const factory AccountDetailState({
    @Default(false) bool loading,
    Profile? profile,
  }) = _AccountDetailState;
}

@freezed
sealed class AccountDetailEffect with _$AccountDetailEffect {
  const factory AccountDetailEffect() = _AccountDetailEffect;
}
