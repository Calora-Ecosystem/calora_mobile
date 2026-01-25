import 'dart:developer';
import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:calora/common/base/profile_store.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/dashboard/management/dashboard_management.dart';
import 'package:calora/presentation/dashboard/management/dashboard_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:management/management.dart';

@RoutePage()
class DashboardPage extends Managed<DashboardManager, DashboardState, DashboardEffect> {
  const DashboardPage({super.key});

  showuserid() async {
    final userid = await profileStore.getUserId();
    log(userid.toString());
  }

  @override
  Widget builder(context, manager, state) {
    showuserid();
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
                          tabsRouter.activeIndex == 0 ? context.colors.accentSub : context.colors.textSub,
                          BlendMode.srcIn,
                        ),
                      ),
                      title: Strings.home,
                    ),
                    _buildBottomNavigationBarItem(
                      icon: Assets.icons.icCalories.svg(
                        colorFilter: ColorFilter.mode(
                          tabsRouter.activeIndex == 1 ? context.colors.accentSub : context.colors.textSub,
                          BlendMode.srcIn,
                        ),
                      ),
                      title: Strings.calories,
                    ),
                    _buildBottomNavigationBarItem(
                      icon: Assets.icons.icVideoPlayer.svg(
                        colorFilter: ColorFilter.mode(
                          tabsRouter.activeIndex == 2 ? context.colors.accentSub : context.colors.textSub,
                          BlendMode.srcIn,
                        ),
                      ),
                      title: Strings.course,
                    ),
                    _buildBottomNavigationBarItem(
                      icon: Assets.icons.icFootwear.svg(
                        colorFilter: ColorFilter.mode(
                          tabsRouter.activeIndex == 3 ? context.colors.accentSub : context.colors.textSub,
                          BlendMode.srcIn,
                        ),
                      ),
                      title: Strings.steps,
                    ),
                    _buildBottomNavigationBarItem(
                      icon: Assets.icons.icPersonNeutral.svg(
                        colorFilter: ColorFilter.mode(
                          tabsRouter.activeIndex == 4 ? context.colors.accentSub : context.colors.textSub,
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
                  onTap: tabsRouter.setActiveIndex,
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
