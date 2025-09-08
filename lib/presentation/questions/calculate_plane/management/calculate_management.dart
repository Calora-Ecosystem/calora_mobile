import 'package:freezed_annotation/freezed_annotation.dart';

part 'calculate_management.freezed.dart';

@freezed
abstract class CalculateState with _$CalculateState {
  factory CalculateState() = _QuestionsState;

  factory CalculateState.initial() => CalculateState();
}

@freezed
sealed class CalculateEffect with _$CalculateEffect {
  const factory CalculateEffect() = _CalculateEffect;
}
