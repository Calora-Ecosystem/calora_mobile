import 'package:calora/domain/model/verification/verification.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:calora/domain/model/questions/questions.dart';

part 'questions_management.freezed.dart';

@freezed
abstract class QuestionsState with _$QuestionsState {
  const factory QuestionsState({
    @Default(Questions()) Questions? answers,
    @Default(0) int currentIndex,
    @Default(false) bool isLoading,
  }) = _QuestionsState;
}

@freezed
sealed class QuestionsEffect with _$QuestionsEffect {
  const factory QuestionsEffect.withType(
    QuestionsEffectType type, {
    /// Backend error message for [QuestionsEffectType.error]; null otherwise.
    String? message,
  }) = _QuestionsEffect;
}

enum QuestionsEffectType { success, error, empty }
