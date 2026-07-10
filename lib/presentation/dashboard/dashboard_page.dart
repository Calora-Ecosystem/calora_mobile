import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:calora/common/base/step_ledger_store.dart';
import 'package:calora/common/di/injection.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/common/service/course_tab_signal.dart';
import 'package:calora/common/widgets/feature_tour/feature_tour.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:calora/presentation/dashboard/management/dashboard_management.dart';
import 'package:calora/presentation/dashboard/management/dashboard_manager.dart';
import 'package:calora/presentation/dashboard/widgets/battery_optimization_dialog.dart';
import 'package:calora/presentation/dashboard/widgets/health_connect_hint_dialog.dart';
import 'package:calora/presentation/dashboard/widgets/health_sync_fix_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:management/management.dart';

@RoutePage()
class DashboardPage extends Managed<DashboardManager, DashboardState, DashboardEffect> {
  const DashboardPage({super.key});

  @override
  void init(BuildContext context, DashboardManager manager) {
    manager.initialize();
    super.init(context, manager);
    _maybePromptBatteryWhitelist(context, manager);
  }

  /// After the dashboard is up, if the app isn't exempt from battery
  /// optimization (and we haven't asked before), guide the user to
  /// whitelist it so the step foreground service survives in the
  /// background.
  void _maybePromptBatteryWhitelist(
    BuildContext context,
    DashboardManager manager,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Don't stack the battery dialog on top of the first-run feature
      // tour — defer it until a later launch once the tour is done.
      if (!StepLedgerStore().isFeatureTourShown()) return;
      if (!await manager.shouldPromptBatteryWhitelist()) return;
      await manager.markBatteryHintShown();
      if (!context.mounted) return;
      await BatteryOptimizationDialog.show(context);
    });
  }

  @override
  void listener(BuildContext context, DashboardManager manager, DashboardEffect effect) {
    effect.when(
      forceLogout: () => context.router.replaceAll([AuthRoute()]),
      requestHealthPermission: (detectedApp) {
        HealthConnectHintDialog.show(
          context: context,
          detectedApp: detectedApp,
          onAccept: () => manager.onUserAcceptedHealthPermission(),
          onDecline: () => manager.onUserDeclinedHealthPermission(),
        );
      },
      requestHealthSyncFix: (detectedApp) {
        HealthSyncFixDialog.show(
          context: context,
          detectedApp: detectedApp,
          onOpenSourceApp: () => manager.onOpenHealthApp(detectedApp),
          onUseSensorInstead: () => manager.onUseSensorInstead(),
          onDismiss: () {},
        );
      },
    );
  }

  @override
  Widget builder(context, manager, state) {
    return FeatureTourHost(
      tourId: 'dashboard',
      switchTabs: true,
      steps: _featureTourSteps(context),
      child: AutoTabsScaffold(
      routes: [HomeRoute(), CaloriesRoute(), CourseRoute(), StepsRoute(), ProfileRoute()],
      bottomNavigationBuilder: (context, tabRouter) {
        final tabsRouter = AutoTabsRouter.of(context);
        // Let the feature tour drive the active tab as it walks sections.
        DashboardTabAccess.router = tabsRouter;
        return ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: context.colors.transparent,
                border: Border(top: BorderSide(color: context.colors.strokeSoft)),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  splashFactory: NoSplash.splashFactory,
                  highlightColor: Colors.transparent,
                ),
                child: BottomNavigationBar(
                  backgroundColor: context.colors.white,
                  unselectedLabelStyle: TextStyle(
                    fontSize: 10,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    color: context.colors.textSub,
                  ),
                  selectedLabelStyle: TextStyle(
                    fontSize: 10,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    color: context.colors.accentSub,
                  ),
                  type: BottomNavigationBarType.fixed,
                  items: [
                    _buildBottomNavigationBarItem(
                      icon: Assets.icons.icHome.svg(
                        colorFilter: ColorFilter.mode(
                          tabsRouter.activeIndex == 0
                              ? context.colors.accentSub
                              : context.colors.textSub,
                          BlendMode.srcIn,
                        ),
                      ),
                      title: Strings.home,
                    ),
                    _buildBottomNavigationBarItem(
                      icon: Assets.icons.icCalories.svg(
                        colorFilter: ColorFilter.mode(
                          tabsRouter.activeIndex == 1
                              ? context.colors.accentSub
                              : context.colors.textSub,
                          BlendMode.srcIn,
                        ),
                      ),
                      title: Strings.calories,
                    ),
                    _buildBottomNavigationBarItem(
                      icon: Assets.icons.icVideoPlayer.svg(
                        colorFilter: ColorFilter.mode(
                          tabsRouter.activeIndex == 2
                              ? context.colors.accentSub
                              : context.colors.textSub,
                          BlendMode.srcIn,
                        ),
                      ),
                      title: Strings.course,
                    ),
                    _buildBottomNavigationBarItem(
                      icon: Assets.icons.icFootwear.svg(
                        colorFilter: ColorFilter.mode(
                          tabsRouter.activeIndex == 3
                              ? context.colors.accentSub
                              : context.colors.textSub,
                          BlendMode.srcIn,
                        ),
                      ),
                      title: Strings.steps,
                    ),
                    _buildBottomNavigationBarItem(
                      icon: Assets.icons.icPersonNeutral.svg(
                        colorFilter: ColorFilter.mode(
                          tabsRouter.activeIndex == 4
                              ? context.colors.accentSub
                              : context.colors.textSub,
                          BlendMode.srcIn,
                        ),
                      ),
                      title: Strings.profile,
                    ),
                  ],
                  currentIndex: tabsRouter.activeIndex,
                  selectedItemColor: context.colors.accentSub,
                  unselectedItemColor: context.colors.iconSub,
                  selectedFontSize: 10,
                  onTap: (index) {
                    tabsRouter.setActiveIndex(index);
                    // Tab indexes match the `routes` list above:
                    // 0 Home, 1 Calories, 2 Course, 3 Steps, 4 Profile.
                    // Tapping Course should always trigger a re-fetch so
                    // a freshly-changed app language reflects in the
                    // server-localized course titles.
                    if (index == 2) {
                      getIt<CourseTabSignal>().fire();
                    }
                  },
                ),
              ),
            ),
          ),
        );
      },
      ),
    );
  }

  BottomNavigationBarItem _buildBottomNavigationBarItem({
    required SvgPicture icon,
    required String title,
  }) {
    return BottomNavigationBarItem(icon: icon, label: title);
  }

  /// The first-run coach-mark tour. Each step switches to its tab and
  /// spotlights the **real** control the user will tap (via [TourAnchors]),
  /// so it teaches the actual app — not the bottom-nav icons.
  ///
  /// Order is intentional: adding food comes first (the core action), then a
  /// brief base intro of Course, Steps and Profile.
  List<FeatureTourStep> _featureTourSteps(BuildContext context) {
    final accent = context.colors.accentSub;
    Widget mi(IconData i) => Icon(i, size: 16, color: accent);
    Widget si(SvgGenImage a) => a.svg(
          width: 16,
          height: 16,
          colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
        );

    return [
      // 1) FOOD — the most important action. Spotlight the real green
      // "Add food" button on Home and explain the three ways to add a meal,
      // scanning first.
      FeatureTourStep(
        navIndex: 0,
        targetKey: TourAnchors.homeAddFood,
        icon: Icons.restaurant_rounded,
        title: 'ft_food_title'.tr(),
        description: 'ft_food_desc'.tr(),
        bullets: [
          FeatureTourBullet(si(Assets.icons.icScan), 'ft_food_b2'.tr()),
          FeatureTourBullet(si(Assets.icons.icChat), 'ft_food_b3'.tr()),
          FeatureTourBullet(si(Assets.icons.icPlusCircle), 'ft_food_b1'.tr()),
        ],
      ),
      // 2) COURSE — base intro, spotlighting the first real lesson card.
      FeatureTourStep(
        navIndex: 2,
        targetKey: TourAnchors.courseFirst,
        icon: Icons.play_circle_fill_rounded,
        title: 'ft_course_title'.tr(),
        description: 'ft_course_desc'.tr(),
        bullets: [
          FeatureTourBullet(mi(Icons.play_circle_fill_rounded), 'ft_course_b1'.tr()),
          FeatureTourBullet(mi(Icons.lock_open_rounded), 'ft_course_b2'.tr()),
        ],
      ),
      // 3) STEPS — base intro, spotlighting the period selector.
      FeatureTourStep(
        navIndex: 3,
        targetKey: TourAnchors.stepsPeriod,
        icon: Icons.directions_walk_rounded,
        title: 'ft_steps_title'.tr(),
        description: 'ft_steps_desc'.tr(),
        bullets: [
          FeatureTourBullet(mi(Icons.today_rounded), 'ft_steps_b1'.tr()),
          FeatureTourBullet(
              mi(Icons.calendar_view_week_rounded), 'ft_steps_b2'.tr()),
        ],
      ),
      // 4) PROFILE — base intro only (nav cell).
      FeatureTourStep(
        navIndex: 4,
        icon: Icons.person_rounded,
        title: 'ft_profile_title'.tr(),
        description: 'ft_profile_desc'.tr(),
        bullets: [
          FeatureTourBullet(mi(Icons.flag_rounded), 'ft_profile_b1'.tr()),
          FeatureTourBullet(mi(Icons.tune_rounded), 'ft_profile_b2'.tr()),
        ],
      ),
    ];
  }
}
