import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:calora/common/extensions/bottom_sheet.dart';
import 'package:calora/common/extensions/foods_extension.dart';
import 'package:calora/common/extensions/meal_type_text_extension.dart';
import 'package:calora/common/extensions/number_extension/truncate.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/common/widgets/image/custom_cached_network_image.dart';
import 'package:calora/common/widgets/loading/default_refresh_indicator.dart';
import 'package:calora/common/widgets/loading/shimmer.dart';
import 'package:calora/common/widgets/snack_bar/custom_snack_bar.dart';
import 'package:calora/domain/model/calories/calories_data.dart';
import 'package:calora/domain/model/meal/menu/menu_item.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/meals/management/meals_management.dart';
import 'package:calora/presentation/meals/management/meals_manager.dart' show MealsManager;
import 'package:calora/widgets/app_bar/custom_app_bar.dart';
import 'package:calora/widgets/creator/food_creator.dart';
import 'package:calora/widgets/meals/empty_food_screen.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

@RoutePage()
class MealsPage extends Managed<MealsManager, MealsState, MealsEffect> {
  final MealType type;
  final DateTime dateTime;
  final int categoryId;

  /// When true (Home scan-banner flow), the add-food screen opens immediately
  /// on entering this page, so the user lands straight on manual/scan/voice.
  /// Backing out of the add screen returns here to the logged-foods list.
  final bool openAddOnEnter;

  const MealsPage({
    required this.type,
    super.key,
    required this.dateTime,
    required this.categoryId,
    this.openAddOnEnter = false,
  });

  @override
  void init(BuildContext context, MealsManager manager) {
    manager.fetchMenuItem(dateTime, type);
    manager.fetchSummary(dateTime, type);
    super.init(context, manager);

    if (openAddOnEnter) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        manager.openAddMealPage();
      });
    }
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.router.pop(true);
      },
      child: Scaffold(
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
                        final hasCover = (item.coverUrl ?? '').isNotEmpty;
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.colors.backgroundElevation,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top: dish photo on the left, this food's
                              // nutrition on the right (kcal + macros).
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (hasCover) ...[
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: CustomCachedNetworkImage.thumbnail(
                                        imageUrl: item.coverUrl,
                                        height: 88,
                                        width: 88,
                                        radius: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                  ],
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.baseline,
                                          textBaseline: TextBaseline.alphabetic,
                                          children: [
                                            item.calories
                                                .asFixedTruncated(0)
                                                .text(24, 28, 700)
                                                .c(context.colors.textStrong),
                                            const SizedBox(width: 4),
                                            Strings.kcal
                                                .text(13, 16, 500)
                                                .c(context.colors.textSub),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            _metricChip(context, label: Strings.oils, value: item.fats),
                                            const SizedBox(width: 8),
                                            _metricChip(context, label: Strings.proteins, value: item.proteins),
                                            const SizedBox(width: 8),
                                            _metricChip(context, label: Strings.carbohydrates, value: item.carbohydrates),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Bottom: name + weight, with edit / delete.
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        (item.foodName ?? '')
                                            .text(16, 20, 600)
                                            .c(context.colors.textStrong)
                                            .auto(minSize: 13),
                                        const SizedBox(height: 2),
                                        '${(item.weight ?? 0).asFixedTruncated(0)} gr'
                                            .text(12, 16, 400)
                                            .c(context.colors.textSub),
                                      ],
                                    ),
                                  ),
                                  // Edit any logged food; delete any logged entry.
                                  if (item.foodId != null)
                                    _actionIcon(
                                      context,
                                      icon: Icons.edit_outlined,
                                      color: context.colors.textSub,
                                      background: context.colors.white,
                                      onTap: () => _openEditSheet(context, manager, item),
                                    ),
                                  if (item.id != null) ...[
                                    const SizedBox(width: 6),
                                    _actionIcon(
                                      context,
                                      icon: Icons.delete_outline,
                                      color: context.colors.errorBase,
                                      background: context.colors.errorLighter,
                                      onTap: () => _confirmDelete(context, manager, item),
                                    ),
                                  ],
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
        bottomNavigationBar: !_isFuture(dateTime)
            ? SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Button(onPressed: () => manager.openAddMealPage(), text: Strings.add),
                ),
              )
            : null,
      ),
    );
  }

  Widget _metricChip(
    BuildContext context, {
    required String label,
    required double value,
    bool highlight = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: highlight ? context.colors.accentGreenWhite : context.colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label.text(10, 12, 500).c(context.colors.textSub).auto(minSize: 8),
            const SizedBox(height: 4),
            value
                .asFixedTruncated(0)
                .text(15, 18, 700)
                .c(highlight ? context.colors.accentSub : context.colors.textStrong)
                .auto(minSize: 11),
          ],
        ),
      ),
    );
  }

  Widget _actionIcon(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required Color background,
    required VoidCallback onTap,
  }) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  String _deleteLabel(BuildContext context) {
    switch (context.locale.languageCode) {
      case 'ru':
        return 'Удалить';
      case 'en':
        return 'Delete';
      case 'uz':
      default:
        return 'O‘chirish';
    }
  }

  String _editTitle(BuildContext context) {
    switch (context.locale.languageCode) {
      case 'ru':
        return 'Редактировать блюдо';
      case 'en':
        return 'Edit food';
      case 'uz':
      default:
        return 'Ovqatni tahrirlash';
    }
  }

  String _deleteConfirm(BuildContext context, String name) {
    switch (context.locale.languageCode) {
      case 'ru':
        return 'Удалить «$name» из меню?';
      case 'en':
        return 'Delete "$name" from the menu?';
      case 'uz':
      default:
        return '«$name» menyudan o‘chirilsinmi?';
    }
  }

  void _openEditSheet(BuildContext context, MealsManager manager, MenuItem item) {
    context.showAppBottomSheet(
      child: FoodCreatorWidget(
        title: _editTitle(context),
        submitText: Strings.save,
        imageUrl: item.coverUrl,
        initialName: item.foodName,
        initialCalories: item.calories.round(),
        initialProtein: item.proteins,
        initialFat: item.fats,
        initialCarbs: item.carbohydrates,
        onSubmit: (name, calories, protein, fat, carbs, weight) {
          if (name.isEmpty) {
            CustomSnackBar.show(context, Strings.pleaseEnterFoodName);
            return;
          }
          if (calories == 0 || protein == 0 || fat == 0 || carbs == 0) {
            CustomSnackBar.show(context, Strings.pleaseEnterFoodMetrics);
            return;
          }
          context.router.pop();
          manager.updateFood(item, name, calories, protein, fat, carbs, dateTime, type);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, MealsManager manager, MenuItem item) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: context.colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.colors.errorLighter,
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    size: 32,
                    color: context.colors.errorBase,
                  ),
                ),
                const SizedBox(height: 16),
                _deleteLabel(context)
                    .text(18, 24, 700)
                    .c(context.colors.textStrong)
                    .copyWith(textAlign: TextAlign.center),
                const SizedBox(height: 8),
                _deleteConfirm(context, item.foodName ?? '')
                    .text(14, 20, 400)
                    .c(context.colors.textSub)
                    .copyWith(textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Row(
                  spacing: 12,
                  children: [
                    Expanded(
                      child: Button(
                        type: ButtonType.secondary,
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        text: Strings.cancel,
                        textColor: context.colors.textStrong,
                      ),
                    ),
                    Expanded(
                      child: Button(
                        backgroundColor: context.colors.errorBase,
                        textColor: context.colors.white,
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          manager.deleteMenuItem(item.id!, dateTime, type);
                        },
                        text: _deleteLabel(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double calculatePercent(double? value, double? max) {
    if (value == null || max == null || max <= 0) return 0.0;
    final percent = value / max;
    return percent.clamp(0.0, 1.0);
  }

  /// Only future days block food logging. Today and any past day can be
  /// edited so users can back-fill meals they forgot to record.
  bool _isFuture(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final check = DateTime(date.year, date.month, date.day);
    return check.isAfter(today);
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
