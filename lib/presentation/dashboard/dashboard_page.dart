import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:calora/common/di/injection.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/common/service/course_tab_signal.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/dashboard/management/dashboard_management.dart';
import 'package:calora/presentation/dashboard/management/dashboard_manager.dart';
import 'package:calora/presentation/dashboard/widgets/activity_permission_dialog.dart';
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
      requestActivityPermission: () {
        ActivityPermissionDialog.show(
          context: context,
          onRequest: () => manager.requestActivityPermission(),
          onCheckGranted: () => manager.hasActivityPermission(),
          onIsPermanentlyDenied: () => manager.isActivityPermanentlyDenied(),
          onOpenSettings: () => manager.openActivitySettings(),
          onGranted: () => manager.onActivityPermissionGranted(),
        );
      },
    );
  }

  @override
  Widget builder(context, manager, state) {
    return AutoTabsScaffold(
      routes: [HomeRoute(), CaloriesRoute(), CourseRoute(), StepsRoute(), ProfileRoute()],
      bottomNavigationBuilder: (context, tabRouter) {
        final tabsRouter = AutoTabsRouter.of(context);
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
    );
  }

  BottomNavigationBarItem _buildBottomNavigationBarItem({
    required SvgPicture icon,
    required String title,
  }) {
    return BottomNavigationBarItem(icon: icon, label: title);
  }
}
