import 'package:freezed_annotation/freezed_annotation.dart';

part 'calculate_management.freezed.dart';

@freezed
abstract class CalculateState with _$CalculateState {
  const factory CalculateState({
    @Default([]) List<double> dailyGoals,
    @Default(false) bool isLoading,
    @Default(0.0) double progressPercent,
  }) = _CalculateState;

  factory CalculateState.initial() => const CalculateState();
}

@freezed
sealed class CalculateEffect with _$CalculateEffect {
  const factory CalculateEffect.error(String message) = _CalculateEffectError;
  const factory CalculateEffect.navigateNext() = _CalculateEffectNavigateNext;
}
