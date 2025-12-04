import 'package:freezed_annotation/freezed_annotation.dart';

part 'verify_management.freezed.dart';

@freezed
abstract class VerifyState with _$VerifyState {
  const factory VerifyState({@Default(false) bool loading}) = _VerifyState;
}

@freezed
class VerifyEffect with _$VerifyEffect {
  const factory VerifyEffect.openQuestions(String email) = _OpenQuestions;
  const factory VerifyEffect.openDashboard() = _OpenDashboard;
}
