import 'package:calora/domain/model/verification/verification.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_management.freezed.dart';

@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState({@Default(false) bool checked, @Default(false) bool loading}) =
      _AuthState;
}

@freezed
sealed class AuthEffect with _$AuthEffect {
  const factory AuthEffect.verify(Verification verification) = Verify;
  const factory AuthEffect.registerNeeded(String email) = _RegisterNeeded;
}
