import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_detail_management.freezed.dart';

@freezed
abstract class AccountDetailState with _$AccountDetailState {
  const factory AccountDetailState() = _AccountDetailState;
}

@freezed
class AccountDetailEffect with _$AccountDetailEffect {
  const factory AccountDetailEffect() = _AccountDetailEffect;
}
