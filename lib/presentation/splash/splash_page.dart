import 'package:auto_route/auto_route.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/presentation/splash/management/splash_management.dart';
import 'package:calora/presentation/splash/management/splash_manager.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

@RoutePage()
class SplashPage extends Managed<SplashManager, SplashState, SplashEffect> {
  const SplashPage({super.key});

  @override
  void listener(
    BuildContext context,
    SplashManager manager,
    SplashEffect effect,
  ) {
    super.listener(context, manager, effect);
    effect.when(
      language: () => context.router.replaceAll([const SelectLanguageRoute()]),
      onboarding: () => context.router.replaceAll([const OnboardingRoute()]),
      auth: (isUzbekistan) =>
          context.router.replaceAll([AuthRoute(isUzbekistan: isUzbekistan)]),
      dashboard: () => context.router.replaceAll([const DashboardRoute()]),
      questionary: () => context.router.replaceAll([QuestionsRoute()]),
    );
  }

  @override
  Widget builder(context, manager, state) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Assets.icons.background.image(fit: BoxFit.cover),
          ),
          Center(
            child: Assets.icons.icSplashCalora.image(height: 52, width: 200),
          ),
        ],
      ),
    );
  }
}
