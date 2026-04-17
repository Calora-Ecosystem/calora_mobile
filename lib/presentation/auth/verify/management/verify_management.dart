import 'package:calora/domain/model/verification/verification.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'verify_management.freezed.dart';

@freezed
abstract class VerifyState with _$VerifyState {
  const factory VerifyState({
    @Default(false) bool loading,
    Verification? verification,
  }) = _VerifyState;
}

@freezed
class VerifyEffect with _$VerifyEffect {
  const factory VerifyEffect.openQuestions(String email) = _OpenQuestions;

  const factory VerifyEffect.openDashboard() = _OpenDashboard;

  const factory VerifyEffect.showError(String message) = _ShowError;
}
