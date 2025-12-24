import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/foods_extension.dart';
import 'package:calora/common/extensions/meal_type_text_extension.dart';
import 'package:calora/common/extensions/number_extension/truncate.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/domain/model/calories/calories_data.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/app_bar/custom_app_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../../common/gen/strings.dart';
import '../../common/widgets/button/button.dart';
import 'management/meals_management.dart';
import 'management/meals_manager.dart' show MealsManager;

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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            spacing: 16,
            children: [
              Container(
                width: double.infinity,
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
                            '${state.meal?.mass.asFixedTruncated(0)}'.text(20, 24, 600).c(context.colors.textStrong),
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
                        mealInfoCard(context, title: Strings.carbohydrates, value: state.meal?.carbohydrates ?? 0),
                      ],
                    ),
                  ],
                ),
              ),
              state.menuItems.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Strings.added.text(20, 24, 600).c(context.colors.textStrong),
                        SizedBox(height: 12),
                        ...state.menuItems
                            .map(
                              (item) => Container(
                                width: double.infinity,
                                margin: EdgeInsets.only(bottom: 12),
                                padding: EdgeInsets.all(8),
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
                                        DateFormat(
                                          'HH:mm',
                                        ).format(item.date).text(14, 16, 400).c(context.colors.textSub),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    '${item.foodName} · ${item.weight.asFixedTruncated(1)} '
                                        .text(14, 16, 400)
                                        .c(context.colors.textSub),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        '${Strings.oil[0].toUpperCase() + Strings.oil.substring(1)} : ${item.fats.asFixedTruncated(1)}'
                                            .text(12, 14, 500)
                                            .c(context.colors.textStrong),
                                        SizedBox(width: 8),
                                        '${Strings.proteins[0].toUpperCase() + Strings.proteins.substring(1)} : ${item.proteins.asFixedTruncated(1)}'
                                            .text(12, 14, 500)
                                            .c(context.colors.textStrong),
                                        SizedBox(width: 8),
                                        '${Strings.carbohydrates[0].toUpperCase() + Strings.carbohydrates.substring(1)} : ${item.carbohydrates.asFixedTruncated(1)}'
                                            .text(12, 14, 500)
                                            .c(context.colors.textStrong),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ],
                    )
                  : Column(
                      spacing: 8,
                      children: [
                        Container(
                          height: 240,
                          width: 240,
                          child: ClipPath(
                            clipper: LeftSideClipper(),
                            child: Assets.images.empty.image(fit: BoxFit.fill),
                          ),
                        ),
                        Strings.mealsAreNotAvailable.text(16, 20, 500).c(context.colors.textStrong),
                        Strings.addYourLastMealsHere
                            .text(14, 18, 400)
                            .c(context.colors.textSub)
                            .copyWith(textAlign: TextAlign.center),
                      ],
                    ),
            ],
          ),
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

  Widget mealInfoCard(BuildContext context, {required String title, required double value, String unit = "gr"}) {
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
                  child: '${value.asFixedTruncated(1)}'
                      .text(20, 24, 600)
                      .c(context.colors.textStrong)
                      .auto(maxLines: 1, minSize: 16),
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

class LeftSideClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    path.moveTo(5, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(5, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
