import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/model/questions/questions.dart';

part 'questions_management.freezed.dart';

@freezed
abstract class QuestionsState with _$QuestionsState {
  const factory QuestionsState({
    @Default(QuestionsModel()) QuestionsModel? answers,
    @Default(0) int currentIndex,
  }) = _QuestionsState;
}

@freezed
sealed class QuestionsEffect with _$QuestionsEffect {
  const factory QuestionsEffect.withType() = _QuestionsEffect;
}

enum QuestionsEffectType { success, error, empty }
