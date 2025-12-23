import 'dart:developer';

import 'package:auto_route/auto_route.dart';
import 'package:calora/common/base/profile_store.dart';
import 'package:calora/common/extensions/bottom_sheet.dart';
import 'package:calora/common/extensions/number_extension/truncate.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/common/service/pedometer_service.dart';
import 'package:calora/common/widgets/calendar/calendar_selector_widget.dart';
import 'package:calora/common/widgets/loading/default_refresh_indicator.dart';
import 'package:calora/domain/model/profile/profile_request.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/dashboard/features/home/management/home_management.dart';
import 'package:calora/presentation/dashboard/features/home/management/home_manager.dart';
import 'package:calora/widgets/app_bar/home_app_bar.dart' show HomeAppBar;
import 'package:calora/widgets/home/daily_feed_rate_widget.dart';
import 'package:calora/widgets/plan/daily_plan_widget.dart';
import 'package:calora/widgets/steps/step_card_widget.dart';
import 'package:calora/widgets/water/water_intake_selector.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

@RoutePage()
class HomePage extends Managed<HomeManager, HomeState, HomeEffect> {
  HomePage({super.key});

  late final PedometerService _pedometerService;

  @override
  void init(context, manager) {
    manager.getUserInfo();
    manager.getStepNorm();
    manager.requestPedometerPermissions();
    _initializePedometerService(manager);
  }

  void _initializePedometerService(HomeManager manager) async {
    _pedometerService = PedometerService(
      onTodayStepCountUpdated: (todaySteps) {
        manager.updateTodaySteps(todaySteps);
      },
      onError: (error) => log('StepsPageError: $error'),
    );
    await _pedometerService.initializePedometer();
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
              Positioned.fill(
                child: Column(
                  children: [
                    ValueListenableBuilder<bool>(
                      valueListenable: isScrolled,
                      builder: (context, scrolled, _) {
                        return HomeAppBar(
                          isScrolled: scrolled,
                          profile: snapshot.data,
                          onTabNotification: () => openInbox(context),
                        );
                      },
                    ),
                    Expanded(
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification.metrics.pixels > 10) {
                            isScrolled.value = true;
                          } else {
                            isScrolled.value = false;
                          }
                          return false;
                        },
                        child: DefaultRefreshIndicator(
                          onRefresh: () async => manager.getUserInfo(),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(parent: const ClampingScrollPhysics()),
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              spacing: 16,
                              children: [
                                GestureDetector(
                                  onTap: () => openCalendar(context, manager),
                                  child: DailyPlanWidget(
                                    onBackward: () => manager.updateDay(
                                      (state.day ?? DateTime.now()).subtract(const Duration(days: 1)),
                                    ),
                                    onForward: () =>
                                        manager.updateDay((state.day ?? DateTime.now()).add(const Duration(days: 1))),
                                    date: state.day ?? DateTime.now(),
                                    calories: '${state.targetKcal} kkal',
                                    water: '${state.targetLiters} litr',
                                    steps: state.targetSteps.toString(),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => openCaloraAi(context),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 20),
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      gradient: RadialGradient(
                                        radius: 1.5,
                                        center: Alignment(0.7, 0),
                                        colors: const [Color(0xFFECFFEF), Color(0xFF58AE8A)],
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            spacing: 8,
                                            children: [
                                              Strings.caloraAi.text(24, 30, 700).c(context.colors.white),
                                              Strings.tryItForFree.text(16, 20, 500).c(context.colors.white),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 100, width: 100, child: Assets.images.ai.image()),
                                      ],
                                    ),
                                  ),
                                ),
                                DailyFeedRateWidget(
                                  onAddFoodTap: () => openCaloriesPage(context),
                                  normCalories: state.targetKcal.asFixedTruncated(1).toString(),
                                  nutrients: state.nutrients,
                                  progressPercent: state.remainedCalories / state.targetKcal,
                                  remainedCalories: state.remainedCalories.asFixedTruncated(1).toString(),
                                ),
                                StepCardWidget(
                                  currentSteps: state.currentSteps,
                                  targetSteps: state.targetSteps,
                                  timeInSeconds: state.timeInSeconds,
                                  distanceInKm: state.distanceInKm,
                                  caloriesBurned: state.caloriesBurned,
                                ),
                                WaterIntakeSelector(
                                  onCountChanged: (count) => manager.updateWaterIntake(count * 0.5),
                                  bottleCapacity: state.bottleCapacity,
                                  targetLiters: state.targetLiters,
                                  currentIntake: state.waterIntake,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void openCalendar(BuildContext context, HomeManager manager) {
    context.showAppBottomSheet(child: CalendarSelectorWidget(onDaySelected: (date) => manager.updateDay(date)));
  }

  void openCaloriesPage(BuildContext context) {
    context.router.navigate(const CaloriesRoute());
  }

  void openCaloraAi(BuildContext context) {
    context.router.navigate(const CaloraAiRoute());
  }

  void openInbox(BuildContext context) {
    context.router.navigate(const InboxRoute());
  }
}
