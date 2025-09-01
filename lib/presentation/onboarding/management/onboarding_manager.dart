import 'package:calora/presentation/onboarding/management/onboarding_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class OnboardingManagerManager
    extends Manager<OnboardingState, OnboardingEffect> {
  OnboardingManagerManager() : super(const OnboardingState());
}
