import 'package:freezed_annotation/freezed_annotation.dart';

part 'verify_management.freezed.dart';

@freezed
abstract class VerifyState with _$VerifyState {
  const factory VerifyState({
    @Default(true) bool isStartTime,
    @Default(false) bool loading,
  }) = _VerifyState;
}

@freezed
sealed class VerifyEffect with _$VerifyEffect {
  const factory VerifyEffect() = _VerifyEffect;
}
