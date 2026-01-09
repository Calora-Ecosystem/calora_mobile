import 'package:auto_route/auto_route.dart';
import 'package:calora/common/di/injection.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/data/store/common/common_store.dart';
import 'package:calora/domain/model/onboarding/onboarding.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/indicator/page_indicator.dart';
import 'package:flutter/material.dart';

@RoutePage()
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Assets.icons.background.image(fit: BoxFit.fill),
          ),
          SafeArea(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SizedBox(height: 32),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: PageIndicator(
                          currentPage: _currentPage,
                          pageCount: 4,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          _openAuthPage();
                          _saveOnboardingCompletedFlag();
                        },
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: Assets.icons.icClose.svg(),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32),
                  Expanded(
                    child: PageView(
                      controller: _controller,
                      onPageChanged: (index) =>
                          setState(() => _currentPage = index),
                      children: [
                        _pageItem(
                          Onboarding(
                            title: Strings.changingLifestyle,
                            message: Strings.changingLifestyleDesc,
                          ),
                          context,
                          Assets.icons.icOnboardingDrinkingBoy.image(),
                        ),
                        _pageItem(
                          Onboarding(
                            title: Strings.healthyEating,
                            message: Strings.healthyEatingDesc,
                          ),
                          context,
                          Assets.icons.icOnboardingPhone.image(),
                        ),
                        _pageItem(
                          Onboarding(
                            title: Strings.enoughDay,
                            message: Strings.enoughDayDesc,
                          ),
                          context,
                          Assets.icons.icOnboardingEngagingBoy.image(),
                        ),
                        _pageItem(
                          Onboarding(
                            title: Strings.dailyWaterNorm,
                            message: Strings.dailyWaterNormDesc,
                          ),
                          context,
                          Assets.icons.icOnboardingWaterPhone.image(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageItem(Onboarding onboarding, BuildContext context, Widget image) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        onboarding.title.text(24, 30, 700).c(context.colors.textStrong),
        SizedBox(height: 16),
        onboarding.message.text(16, 20, 400).c(context.colors.textStrong),
        SizedBox(height: 36),
        Expanded(child: image),
      ],
    );
  }

  void _openAuthPage() => {context.router.replace(AuthRoute())};
  void _saveOnboardingCompletedFlag() async =>
      await getIt<CommonStore>().isOnboardingCompleted.set(true);
}
