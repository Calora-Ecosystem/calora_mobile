import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/number_extension/truncate.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/common/widgets/calendar/week_day_selector.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/caloriya/daily_meal_plan_widget.dart';
import 'package:calora/widgets/caloriya/meal_cards_grid.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

import 'management/calories_management.dart';
import 'management/calories_manager.dart';

@RoutePage()
class CaloriesPage extends Managed<CaloriesManager, CaloriesState, CaloriesEffect> {
  const CaloriesPage({super.key});

  @override
  void init(context, manager) {
    manager.getDailyCalories();
    manager.getMealsData();
  }

  @override
  void listener(BuildContext context, CaloriesManager manager, CaloriesEffect effect) {
    super.listener(context, manager, effect);
    effect.when(openMealPage: (type) => context.pushRoute(MealsRoute(type: type)));
  }

  @override
  Widget builder(context, manager, state) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Assets.icons.background.image(fit: BoxFit.fill)),
          Container(
            color: state.isScrolled ? context.colors.softGray : Colors.transparent,
            child: SafeArea(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification.metrics.axis == Axis.horizontal) return false;
                  if (notification is ScrollUpdateNotification) {
                    manager.setScrolled(notification.metrics.pixels > 0);
                  }
                  return false;
                },
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Column(
                    spacing: 16,
                    children: [
                      const SizedBox(height: 40),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: WeekDaysSelector(onDaySelected: (value) {}),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(color: context.colors.white),
                        child: Column(
                          spacing: 8,
                          children: [
                            DailyMealPlanWidget(
                              accordingToPlan: "${state.plan.asFixedTruncated(0)}",
                              consumed: "${state.consumed.asFixedTruncated(0)}",
                              leftover: "${state.leftover.asFixedTruncated(0)}",
                            ),
                            MealCardsGrid(meals: manager.meals),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: context.colors.backgroundElevation,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Assets.icons.greenNotification.svg(),
                                      const SizedBox(width: 8),
                                      Strings.notification.text(20, 24, 600).c(context.colors.textStrong),
                                      Spacer(),
                                      Assets.icons.setting.svg(),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Strings.toRemindYouOfMealTimes.text(14, 16, 400).c(context.colors.textSub),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
