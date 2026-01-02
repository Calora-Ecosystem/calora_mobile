import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/number_extension/truncate.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/common/widgets/calendar/week_day_selector.dart';
import 'package:calora/common/widgets/loading/default_refresh_indicator.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/dashboard/features/calories/management/calories_management.dart';
import 'package:calora/presentation/dashboard/features/calories/management/calories_manager.dart';
import 'package:calora/widgets/caloriya/daily_meal_plan_widget.dart';
import 'package:calora/widgets/caloriya/meal_cards_grid.dart';
import 'package:calora/widgets/notification_widgets/calory_notification_settings.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

@RoutePage()
class CaloriesPage extends Managed<CaloriesManager, CaloriesState, CaloriesEffect> {
  const CaloriesPage({super.key});

  @override
  void init(context, manager) {
    manager.fetchCaloriesAndMeals(DateTime.now());
    manager.getSummary(DateTime.now());
  }

  @override
  void listener(BuildContext context, CaloriesManager manager, CaloriesEffect effect) {
    super.listener(context, manager, effect);
    effect.when(
      openMealPage: (type, meals, date) =>
          context.pushRoute<bool>(MealsRoute(type: type, dateTime: date, categoryId: 1)).then(
            (value) {
              if (value == true) {
                manager.fetchCaloriesAndMeals(date);
                manager.getSummary(date);
              }
            },
          ),
    );
  }

  @override
  Widget builder(context, manager, state) {
    return Scaffold(
      body: DefaultRefreshIndicator(
        onRefresh: () async {
          manager.fetchCaloriesAndMeals(state.date ?? DateTime.now());
          manager.getSummary(state.date ?? DateTime.now());
        },
        child: Stack(
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
                          child: WeekDaysSelector(
                            onDaySelected: (value) {
                              manager.fetchCaloriesAndMeals(value);
                              manager.getSummary(value);
                              manager.dateTime(value);
                            },
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(color: context.colors.white),
                          child: Column(
                            spacing: 8,
                            children: [
                              DailyMealPlanWidget(
                                accordingToPlan: state.plan.asFixedTruncated(0),
                                consumed: state.consumed.asFixedTruncated(0),
                                leftover: state.leftover.asFixedTruncated(0),
                                loading: state.isLoading,
                              ),
                              MealCardsGrid(meals: manager.meals, isLoading: state.isLoading),
                              CaloryNotificationSettings(),
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
      ),
    );
  }
}
