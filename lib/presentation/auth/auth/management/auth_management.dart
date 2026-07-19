import 'package:calora/domain/model/verification/verification.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_management.freezed.dart';

@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState({
    @Default(false) bool loading,
    @Default(false) bool checked,
    @Default(false) bool isUzbekistan,
    @Default(true) bool countryLoading,
    @Default(false) bool countryError,
  }) = _AuthState;
}

@freezed
class AuthEffect with _$AuthEffect {
  const factory AuthEffect.verify(Verification verification) = _Verify;

  const factory AuthEffect.showError(String message) = _ShowError;

  const factory AuthEffect.openQuestions(String identifier) = _OpenQuestions;

  const factory AuthEffect.openDashboard() = _OpenDashboard;
}
