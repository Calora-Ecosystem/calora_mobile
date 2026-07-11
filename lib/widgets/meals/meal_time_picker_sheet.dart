import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:calora/common/base/manager_builder.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/dashboard/features/calories/management/calories_management.dart';
import 'package:calora/presentation/dashboard/features/calories/management/calories_manager.dart';
import 'package:calora/widgets/caloriya/meal_cards_grid.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

/// Bottom sheet opened from the Home scan banner. It reuses the exact meal
/// section from the Calories page — the daily-plan summary plus the per-meal
/// cards that show consumed kcal (not clock times). Tapping a meal opens the
/// same add-food screen the Calories page uses; when food is logged the kcal
/// refresh live in the sheet and [onLogged] lets Home update its totals.
Future<void> showMealTimePicker(
  BuildContext context, {
  VoidCallback? onLogged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MealCaloriesSheet(onLogged: onLogged),
  );
}

class _MealCaloriesSheet extends StatefulWidget {
  final VoidCallback? onLogged;

  const _MealCaloriesSheet({this.onLogged});

  @override
  State<_MealCaloriesSheet> createState() => _MealCaloriesSheetState();
}

class _MealCaloriesSheetState extends State<_MealCaloriesSheet> {
  late final CaloriesManager _manager;
  StreamSubscription<CaloriesEffect>? _effectSub;

  @override
  void initState() {
    super.initState();
    _manager = GetIt.instance<CaloriesManager>();
    _manager.dateTime(DateTime.now());
    _manager.fetchCaloriesAndMeals(DateTime.now());
    _effectSub = _manager.effectSubject.listen(_onEffect);
  }

  void _onEffect(CaloriesEffect effect) {
    effect.when(
      openMealPage: (type, meals, date) async {
        // Skip the intermediate meal-list screen — open the scan / manual /
        // voice add-food page directly for the chosen meal.
        final result = await context.pushRoute<bool>(
          AddMealsRoute(
            type: type,
            meals: const [],
            dateTime: date,
            categoryId: 1,
          ),
        );
        if (result == true && mounted) {
          widget.onLogged?.call();
          _manager.fetchCaloriesAndMeals(date);
        }
      },
    );
  }

  @override
  void dispose() {
    _effectSub?.cancel();
    _manager.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: context.colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 44,
                decoration: BoxDecoration(
                  color: context.colors.neutral200Stroke,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            const SizedBox(height: 20),
            'pick_meal_title'
                .tr()
                .text(22, 28, 700)
                .c(context.colors.textStrong),
            const SizedBox(height: 6),
            'pick_meal_subtitle'
                .tr()
                .text(14, 20, 400)
                .c(context.colors.textSub),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: ManagerBuilder<CaloriesState, CaloriesEffect>(
                  manager: _manager,
                  properties: (s) => [s.isLoading, s.meals],
                  builder: (context, state) {
                    return MealCardsGrid(
                      meals: _manager.meals,
                      isLoading: state.isLoading,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
