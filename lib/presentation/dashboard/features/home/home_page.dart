import 'package:auto_route/annotations.dart';
import 'package:calora/common/base/profile_store.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/domain/model/profile/profile_request.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/dashboard/features/home/management/home_management.dart';
import 'package:calora/presentation/dashboard/features/home/management/home_manager.dart';
import 'package:calora/widgets/app_bar/home_app_bar.dart' show HomeAppBar;
import 'package:calora/widgets/plan/daily_plan_widget.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

@RoutePage()
class HomePage extends Managed<HomeManager, HomeState, HomeEffect> {
  HomePage({super.key});

  @override
  void init(context, manager) {
    manager.getUserInfo();
    manager.requestPedometerPermissions();
  }

  @override
  Widget builder(context, manager, state) {
    return StreamBuilder<ProfileRequest>(
      stream: profileStore.watch(),
      builder: (context, snapshot) {
        final ValueNotifier<bool> isScrolled = ValueNotifier(false);
        return Scaffold(
          body: Stack(
            children: [
              Positioned.fill(child: Assets.icons.background.image(fit: BoxFit.fill)),
              NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification.metrics.pixels > 10) {
                    isScrolled.value = true;
                  } else {
                    isScrolled.value = false;
                  }
                  return true;
                },
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    spacing: 16,
                    children: [
                      ValueListenableBuilder<bool>(
                        valueListenable: isScrolled,
                        builder: (context, scrolled, _) {
                          return HomeAppBar(
                            isScrolled: scrolled,
                            profile: state.profile,
                            onTabNotification: () {},
                          );
                        },
                      ),
                      DailyPlanWidget(
                        onBackward: () {},
                        onForward: () {},
                        day: '25',
                        month: 'Iyul',
                        calories: '2241 kkal',
                        water: '2.45 litr',
                        steps: '6000',
                      ),
                      Assets.images.ai.image(),
                      Container(
                        padding: EdgeInsets.all(20),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: RadialGradient(
                            radius: 1.5,
                            center: Alignment(0.7, 0),
                            colors: [Color(0xFFECFFEF), Color(0xFF58AE8A)],
                          ),
                        ),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 8,
                              children: [
                                'Calora Ai'.text(24, 30, 700).c(context.colors.white),
                                Strings.tryItForFree.text(16, 20, 500).c(context.colors.white),
                              ],
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
      },
    );
  }
}
