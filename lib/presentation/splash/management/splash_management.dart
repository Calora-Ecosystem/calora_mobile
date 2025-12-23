import 'package:freezed_annotation/freezed_annotation.dart';

part 'splash_management.freezed.dart';

@freezed
abstract class SplashState with _$SplashState {
  const factory SplashState() = _SplashState;
}

@freezed
sealed class SplashEffect with _$SplashEffect {
  const factory SplashEffect.dashboard() = _Dashboard;
  const factory SplashEffect.language() = _Language;
  const factory SplashEffect.auth() = _Auth;
  const factory SplashEffect.onboarding() = _Onboarding;
}
