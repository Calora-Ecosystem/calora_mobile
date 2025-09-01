import 'package:freezed_annotation/freezed_annotation.dart';

part 'onboarding_management.freezed.dart';

@freezed
abstract class OnboardingState with _$OnboardingState {
  const factory OnboardingState() = _OnboardingState;
}

@freezed
sealed class OnboardingEffect with _$OnboardingEffect {
  const factory OnboardingEffect() = _OnboardingEffect;
}
