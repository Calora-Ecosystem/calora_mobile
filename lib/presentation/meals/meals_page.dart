import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/foods_extension.dart';
import 'package:calora/common/extensions/meal_type_text_extension.dart';
import 'package:calora/common/extensions/number_extension/truncate.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/common/widgets/loading/default_refresh_indicator.dart';
import 'package:calora/common/widgets/loading/shimmer.dart';
import 'package:calora/domain/model/calories/calories_data.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/app_bar/custom_app_bar.dart';
import 'package:calora/widgets/meals/empty_food_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/presentation/meals/management/meals_management.dart';
import 'package:calora/presentation/meals/management/meals_manager.dart' show MealsManager;

@RoutePage()
class MealsPage extends Managed<MealsManager, MealsState, MealsEffect> {
  final MealType type;
  final DateTime dateTime;
  final int categoryId;

  const MealsPage({
    required this.type,
    super.key,
    required this.dateTime,
    required this.categoryId,
  });

  @override
  void init(BuildContext context, MealsManager manager) {
    manager.fetchMenuItem(dateTime, type);
    manager.fetchSummary(dateTime, type);
    super.init(context, manager);
  }

  @override
  void listener(BuildContext context, MealsManager manager, MealsEffect effect) {
    super.listener(context, manager, effect);
    effect.mapOrNull(
      openAddMealPage: (value) {
        context
            .pushRoute<bool>(
              AddMealsRoute(type: type, meals: manager.state.meals, dateTime: dateTime, categoryId: categoryId),
            )
            .then((result) {
              if (result == true && context.mounted) {
                manager.fetchMenuItem(dateTime, type);
                manager.fetchSummary(dateTime, type);
              }
            });
      },
    );
  }

  @override
  Widget builder(BuildContext context, MealsManager manager, MealsState state) {
    return Scaffold(
      backgroundColor: context.colors.white,
      appBar: CustomAppBar(
        title: Strings.addFood,
        onBack: () => context.router.pop(true),
      ),
      body: DefaultRefreshIndicator(
        onRefresh: () async {
          manager.fetchMenuItem(dateTime, type);
          manager.fetchSummary(dateTime, type);
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  ShimmerWrapper(
                    type: ShimmerType.backgroundElevation,
                    loading: state.isSummary,
                    shimmerChild: ShimmerChild(height: 180),
                    child: Container(
                      width: double.infinity,
                      height: 180,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.colors.backgroundElevation,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        spacing: 12,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              type.title.text(20, 24, 600).c(context.colors.textStrong),
                              Row(
                                spacing: 4,
                                children: [
                                  '${state.meal?.mass.asFixedTruncated(0)}'
                                      .text(20, 24, 600)
                                      .c(context.colors.textStrong),
                                  'gr'.text(20, 24, 600).c(context.colors.textSub),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            spacing: 4,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  '${state.meal?.value.asFixedTruncated(1)} ${Strings.kcal}'
                                      .text(12, 16, 500)
                                      .c(context.colors.textSub),
                                  '${state.meal?.max.asFixedTruncated(1)} ${Strings.kcal}'
                                      .text(12, 16, 500)
                                      .c(context.colors.textSub),
                                ],
                              ),
                              LinearPercentIndicator(
                                lineHeight: 16,
                                animateFromLastPercent: true,
                                animation: true,
                                barRadius: Radius.circular(4),
                                padding: EdgeInsets.zero,
                                percent: calculatePercent(state.meal?.value, state.meal?.max),
                                backgroundColor: context.colors.white,
                                progressColor: context.colors.accentSub,
                              ),
                            ],
                          ),
                          Row(
                            spacing: 8,
                            children: [
                              mealInfoCard(context, title: Strings.oils, value: state.meal?.oils ?? 0),
                              mealInfoCard(context, title: Strings.proteins, value: state.meal?.proteins ?? 0),
                              mealInfoCard(
                                context,
                                title: Strings.carbohydrates,
                                value: state.meal?.carbohydrates ?? 0,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Strings.added.text(20, 24, 600).c(context.colors.textStrong),
                ],
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (state.isLoading) {
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: 2,
                      itemBuilder: (context, index) {
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          height: 86,
                          decoration: BoxDecoration(
                            color: context.colors.backgroundElevation,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        );
                      },
                    );
                  }
                  if (state.menuItems.isEmpty) {
                    return SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
                      child: Center(
                        child: EmptyFoodScreen(
                          message: Strings.addYourLastMealsHere,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: state.menuItems.length,
                    itemBuilder: (context, index) {
                      final item = state.menuItems[index];
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.colors.backgroundElevation,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                '${item.calories.asFixedTruncated(1)} ${Strings.kcal}'
                                    .text(16, 20, 500)
                                    .c(context.colors.textStrong),
                                DateFormat('HH:mm').format(item.date).text(14, 16, 400).c(context.colors.textSub),
                              ],
                            ),
                            const SizedBox(height: 4),
                            '${item.foodName} · ${item.weight.asFixedTruncated(1)}'
                                .text(14, 16, 400)
                                .c(context.colors.textSub),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                '${Strings.oils}:${item.fats.asFixedTruncated(1)}'
                                    .text(12, 14, 500)
                                    .c(context.colors.textStrong),
                                const SizedBox(width: 8),
                                '${Strings.proteins}:${item.proteins.asFixedTruncated(1)}'
                                    .text(12, 14, 500)
                                    .c(context.colors.textStrong),
                                const SizedBox(width: 8),
                                '${Strings.carbohydrates}:${item.carbohydrates.asFixedTruncated(1)}'
                                    .text(12, 14, 500)
                                    .c(context.colors.textStrong),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _isToday(dateTime)
          ? Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Button(onPressed: () => manager.openAddMealPage(), text: Strings.add),
            )
          : null,
    );
  }

  double calculatePercent(double? value, double? max) {
    if (value == null || max == null || max <= 0) return 0.0;
    final percent = value / max;
    return percent.clamp(0.0, 1.0);
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return now.year == date.year && now.month == date.month && now.day == date.day;
  }

  Widget mealInfoCard(BuildContext context, {required String title, required double value, String unit = 'gr'}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: context.colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            title.text(12, 16, 500).c(context.colors.textSub),
            const SizedBox(height: 16),
            Row(
              spacing: 4,
              children: [
                Expanded(
                  child: value.asFixedTruncated(1).text(20, 24, 600).c(context.colors.textStrong).auto(minSize: 16),
                ),
                unit.text(20, 24, 600).c(context.colors.textSub),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
