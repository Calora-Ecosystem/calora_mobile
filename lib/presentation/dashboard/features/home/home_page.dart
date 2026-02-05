import 'dart:developer';

import 'package:auto_route/auto_route.dart';
import 'package:calora/common/base/manager_builder.dart';
import 'package:calora/common/base/profile_store.dart';
import 'package:calora/common/di/injection.dart';
import 'package:calora/common/extensions/bottom_sheet.dart';
import 'package:calora/common/extensions/number_extension/truncate.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/common/service/pedometer_service.dart';
import 'package:calora/common/widgets/calendar/calendar_selector_widget.dart';
import 'package:calora/common/widgets/confetti/confetti.dart';
import 'package:calora/common/widgets/loading/default_refresh_indicator.dart';
import 'package:calora/domain/model/profile/profile_request.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/dashboard/features/home/management/home_management.dart';
import 'package:calora/presentation/dashboard/features/home/management/home_manager.dart';
import 'package:calora/presentation/dashboard/management/dashboard_management.dart';
import 'package:calora/presentation/dashboard/management/dashboard_manager.dart';
import 'package:calora/widgets/app_bar/home_app_bar.dart' show HomeAppBar;
import 'package:calora/widgets/home/daily_feed_rate_widget.dart';
import 'package:calora/widgets/plan/daily_plan_widget.dart';
import 'package:calora/widgets/steps/step_card_widget.dart';
import 'package:calora/widgets/water/water_intake_selector.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

@RoutePage()
class HomePage extends Managed<HomeManager, HomeState, HomeEffect> {
  HomePage({super.key});

  TabsRouter? _tabsRouter;
  int _lastIndex = 0;

  final ValueNotifier<bool> _isScrolled = ValueNotifier(false);

  @override
  void init(BuildContext context, HomeManager manager) {
    manager.updateDay(DateTime.now());
    manager.refreshAll();
    context.read<DashboardManager>().initialize();
    Future.microtask(() => manager.initStepsForeground());

    _tabsRouter = AutoTabsRouter.of(context);
    _lastIndex = _tabsRouter!.activeIndex;

    _tabsRouter!.addListener(() {
      final idx = _tabsRouter!.activeIndex;
      if (_lastIndex != 0 && idx == 0) manager.refreshAll();
      _lastIndex = idx;
    });
  }

  @override
  Widget builder(BuildContext context, HomeManager manager, HomeState state) {
    final pedometerService = getIt<PedometerService>();
    return StreamBuilder<ProfileRequest>(
      stream: profileStore.watch(),
      builder: (context, snapshot) {
        return Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: Assets.icons.background.image(fit: BoxFit.fill),
              ),
              Positioned.fill(
                child: Column(
                  children: [
                    ValueListenableBuilder<bool>(
                      valueListenable: _isScrolled,
                      builder: (context, scrolled, _) {
                        return HomeAppBar(
                          isScrolled: scrolled,
                          profile: snapshot.data,
                          unreadCount: state.unreadCount,
                          onTabNotification: () => openInbox(context),
                        );
                      },
                    ),
                    Expanded(
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          _isScrolled.value = notification.metrics.pixels > 10;
                          return false;
                        },
                        child: DefaultRefreshIndicator(
                          onRefresh: () async => manager.refreshAll(),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: ClampingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              spacing: 16,
                              children: [
                                DailyPlanWidget(
                                  onDateTap: () => openCalendar(context, manager),
                                  loading: state.isLoading,
                                  onBackward: () {
                                    final newDay = (state.day ?? DateTime.now()).subtract(const Duration(days: 1));
                                    manager.updateDay(newDay);
                                    manager.getSummary();
                                    manager.getWater();
                                  },
                                  onForward: () {
                                    final newDay = (state.day ?? DateTime.now()).add(const Duration(days: 1));
                                    manager.updateDay(newDay);
                                    manager.getSummary();
                                    manager.getWater();
                                  },
                                  date: state.day ?? DateTime.now(),
                                  calories: '${state.targetKcal.asFixedTruncated(0)} ${Strings.kcal}',
                                  water: '${state.targetLiters} ${Strings.liter}',
                                  steps: state.targetSteps.toString(),
                                ),

                                GestureDetector(
                                  onTap: () => openCaloraAi(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      gradient: const RadialGradient(
                                        radius: 1.5,
                                        center: Alignment(0.7, 0),
                                        colors: [Color(0xFFECFFEF), Color(0xFF58AE8A)],
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
                                        SizedBox(
                                          height: 100,
                                          width: 100,
                                          child: Assets.images.ai.image(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                DailyFeedRateWidget(
                                  onAddFoodTap: () => openCaloriesPage(context),
                                  normCalories: (state.summary?.kcalNorm.value ?? 0).asFixedTruncated(0).toString(),
                                  nutrients: state.nutrients,
                                  progressPercent:
                                      (state.summary?.sum.Kcal ?? 0) / (state.summary?.kcalNorm.value ?? 0),
                                  remainedCalories:
                                      (state.summary?.kcalNorm.value ?? 0) - (state.summary?.sum.Kcal ?? 0),
                                  loading: state.isSummaryLoading,
                                ),
                                _buildStepCardWithStream(
                                  context: context,
                                  pedometerService: pedometerService,
                                  state: state,
                                  manager: manager,
                                ),
                                WaterIntakeSelector(
                                  loading: state.isWaterLoading,
                                  date: state.day ?? DateTime.now(),
                                  onCountChanged: (count) {
                                    manager.updateWaterIntake(count * 0.25);
                                    manager.postWater();
                                  },
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

  Widget _buildStepCardWithStream({
    required BuildContext context,
    required PedometerService pedometerService,
    required HomeState state,
    required HomeManager manager,
  }) {
    final selectedDay = state.day ?? DateTime.now();
    final isToday = _isToday(selectedDay);

    if (!isToday) {
      return StepCardWidget(
        loading: state.isMetricsLoading,
        currentSteps: state.currentSteps,
        targetSteps: state.targetSteps,
        timeInSeconds: state.metrics?.duration ?? 0,
        distanceInKm: state.metrics?.distance ?? 0,
        caloriesBurned: state.metrics?.kcal ?? 0,
      );
    }
    return ManagerBuilder<DashboardState, DashboardEffect>(
      manager: context.read<DashboardManager>(),
      properties: (s) => [s.todaySteps],
      builder: (context, dashState) {
        final currentSteps = dashState.todaySteps;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (currentSteps != state.currentSteps) {
            manager.updateTodaySteps(currentSteps);
          }
        });

        return StepCardWidget(
          loading: false,
          currentSteps: currentSteps,
          targetSteps: state.targetSteps,
          timeInSeconds: state.metrics?.duration ?? 0,
          distanceInKm: state.metrics?.distance ?? 0,
          caloriesBurned: state.metrics?.kcal ?? 0,
        );
      },
    );
  }

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return now.year == day.year && now.month == day.month && now.day == day.day;
  }

  void openCalendar(BuildContext context, HomeManager manager) {
    context.showAppBottomSheet(
      child: CalendarSelectorWidget(
        initialDate: manager.state.day ?? DateTime.now(),
        onDaySelected: (date) {
          manager.updateDay(date);
          manager.getSummary();
          manager.getWater();
        },
      ),
    );
  }

  void openCaloriesPage(BuildContext context) {
    context.router.navigate(const CaloriesRoute());
  }

  void openCaloraAi(BuildContext context) {
    context.router.navigate(const CaloraAiRoute());
  }

  void openInbox(BuildContext context) async {
    context.router.navigate(const InboxRoute());
    final token = await FirebaseMessaging.instance.getToken();
    log('FCM TOKEN: $token');
  }
}
