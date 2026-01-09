import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:calora/common/base/profile_store.dart';
import 'package:calora/common/extensions/assets_extension.dart';
import 'package:calora/common/extensions/bottom_sheet.dart';
import 'package:calora/common/extensions/foods_extension.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/common/widgets/button/toggle_buttons.dart';
import 'package:calora/common/widgets/snack_bar/custom_snack_bar.dart';
import 'package:calora/common/widgets/text_field/common_text_field.dart';
import 'package:calora/domain/model/calories/calories_data.dart';
import 'package:calora/domain/model/meal/food/food_models.dart';
import 'package:calora/domain/model/meal/food_request/food_request.dart';
import 'package:calora/domain/model/meal/menu/menu_info.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/meals/add/management/add_meals_management.dart';
import 'package:calora/presentation/meals/add/management/add_meals_manager.dart';
import 'package:calora/presentation/speech/speech_page.dart';
import 'package:calora/widgets/app_bar/custom_app_bar.dart';
import 'package:calora/widgets/creator/food_creator.dart';
import 'package:calora/widgets/creator/food_creator_with_image.dart';
import 'package:calora/widgets/creator/food_creator_with_speech.dart';
import 'package:calora/widgets/info/dish_info_page.dart';
import 'package:calora/widgets/meals/meals_type_widget.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

@RoutePage()
class AddMealsPage extends Managed<AddMealsManager, AddMealsState, AddMealsEffect> {
  final bool shouldOpenCreator;
  final MealType type;
  final List<MealData> meals;
  final DateTime dateTime;
  final int categoryId;

  AddMealsPage({
    super.key,
    required this.meals,
    required this.dateTime,
    required this.categoryId,
    required this.type,
    this.shouldOpenCreator = false,
  });

  late final TextEditingController _searchController;
  Timer? _debounce;

  @override
  void init(BuildContext context, AddMealsManager manager) {
    _searchController = TextEditingController();
    _searchController.addListener(() => _onSearchChanged(manager));
    super.init(context, manager);
    manager.fetchFoodCategory();
  }

  void _onSearchChanged(AddMealsManager manager) {
    final text = _searchController.text.trim();
    _debounce?.cancel();

    if (text.isEmpty) {
      manager.onSearchChanged('');
      return;
    }

    if (text.length >= 3) {
      // 200ms debounce
      _debounce = Timer(const Duration(milliseconds: 200), () {
        manager.onSearchChanged(text);
      });
    }
  }

  @override
  void listener(BuildContext context, AddMealsManager manager, AddMealsEffect effect) {
    super.listener(context, manager, effect);
    effect.mapOrNull(
      openDishesPage: (e) => context.pushRoute(
        DishesRoute(data: e.meal, type: type, categoryId: categoryId, meals: meals, dateTime: dateTime),
      ),
      openAboutPage: (e) => openAboutDishPage(context, e.food, manager, e.isFavourite),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget builder(BuildContext context, AddMealsManager manager, AddMealsState state) {
    return Scaffold(
      backgroundColor: context.colors.white,
      appBar: CustomAppBar(
        title: Strings.add,
        onBack: () => context.router.pop(true),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            spacing: 12,
            children: [
              CommonTextField(
                hint: Strings.searchForFoodOrProduct,
                controller: _searchController,
              ),
              if (!state.isSearchMode) ...[
                Row(
                  spacing: 8,
                  children: [
                    buildActionCard(
                      onTap: () => openCreatePage(context, manager),
                      context: context,
                      icon: Assets.icons.icPlusCircle.svg(),
                      text: Strings.creation,
                      textColor: context.colors.textStrong,
                    ),
                    buildActionCard(
                      onTap: () => openCameraPage(context, manager),
                      context: context,
                      icon: Assets.icons.icScan.svg(),
                      text: Strings.scanning,
                      textColor: context.colors.textWhite,
                      useGradient: true,
                    ),
                    buildActionCard(
                      onTap: () => openSpeechPage(context, manager),
                      context: context,
                      icon: Assets.icons.icChat.svg(),
                      text: Strings.byVoice,
                      textColor: context.colors.textWhite,
                      useGradient: true,
                    ),
                  ],
                ),
                ToggleButtonsWidget(
                  onChanged: (value) => manager.onToggleChanged(value),
                  titles: [Strings.allDishes, Strings.lastEaten, Strings.thoseICreated, Strings.favoriteFoods],
                ),
                Flexible(
                  child: state.selectedToggleIndex == 3
                      ? RepaintBoundary(
                          child: FavouriteFoodGrid(
                            isLoading: state.isFavourite,
                            foods: state.favouriteFoods,
                            onFoodSelected: (food) => manager.openAboutPage(food, food.isFavourite),
                          ),
                        )
                      : state.selectedToggleIndex == 1
                      ? RepaintBoundary(
                          child: FavouriteFoodGrid(
                            isLoading: state.isLatest,
                            foods: state.latestFoods,
                            onFoodSelected: (food) => manager.openAboutPage(food, food.isFavourite),
                          ),
                        )
                      : state.selectedToggleIndex == 2
                      ? RepaintBoundary(
                          child: FavouriteFoodGrid(
                            isLoading: state.isUserFoods,
                            foods: state.userFoods,
                            onFoodSelected: (food) => manager.openAboutPage(food, food.isFavourite),
                          ),
                        )
                      : RepaintBoundary(
                          child: MealTypeGrid(
                            isLoading: state.isMealCategory,
                            mealTypes: state.mealCategories,
                            onMealTypeSelected: (meal) => manager.openDishesPage(meal),
                          ),
                        ),
                ),
              ],
              if (state.isSearchMode)
                Expanded(
                  child: FavouriteFoodGrid(
                    isLoading: state.isSearch,
                    foods: state.searchFoods,
                    onFoodSelected: (food) => manager.openAboutPage(food, food.isFavourite),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void openAboutDishPage(BuildContext context, FoodModel food, AddMealsManager manager, bool isFavourite) {
    context.showAppBottomSheet(
      child: DishInfoPage(
        isFavourite: isFavourite,
        foodItem: food,
        onFavouriteChanged: (value) {
          if (value) manager.addFavourite(food.id ?? 0);
        },
        onSave: (value) async {
          manager.addFavourite(food.id ?? 0);
          final success = await manager.saveMenuItem(
            MenuInfo(menu: type.name, date: DateTime.now(), foodId: food.id ?? 0, weightInGr: value.toInt()),
          );
          if (context.mounted) context.router.pop();

          if (success) {
            _showInfoDialog(context);
          }
        },
      ),
    );
  }

  void openCreatePage(BuildContext context, AddMealsManager manager) {
    context.showAppBottomSheet(
      child: FoodCreatorWidget(
        onSubmit: (name, calories, protein, fat, carbs) async {
          if (name.isEmpty) {
            CustomSnackBar.show(context, Strings.pleaseEnterFoodName);
            return;
          }
          if (calories == 0 || protein == 0 || fat == 0 || carbs == 0) {
            CustomSnackBar.show(context, Strings.pleaseEnterFoodMetrics);
            return;
          }
          final int userId = await profileStore.getUserId() ?? 0;
          final addedFoodId = await manager.addFood(
            FoodRequest(
              categoryId: categoryId,
              name: FoodName(uz: name, ru: name, eng: name, cyrl: name),
              coverUrl: abstractImageUrl,
              metrics: [
                Metric(userId: 0, metric: MetricType.kcal.name, value: calories),
                Metric(userId: 0, metric: MetricType.protein.name, value: protein),
                Metric(userId: 0, metric: MetricType.fat.name, value: fat),
                Metric(userId: 0, metric: MetricType.carb.name, value: carbs),
              ],
              userId: userId,
            ),
          );

          bool success = false;
          if (addedFoodId != null) {
            success = await manager.saveMenuItem(
              MenuInfo(menu: type.name, date: DateTime.now(), foodId: addedFoodId, weightInGr: 400),
            );
          }
          if (context.mounted) context.router.pop();
          if (success) {
            _showInfoDialog(context);
          }
        },
      ),
    );
  }

  void openCreatorWithImage(BuildContext context, AddMealsManager manager, ScannerFood food) {
    final metrics = food.metrics;
    context.showAppBottomSheet(
      child: FoodCreatorWithImage(
        isLoading: manager.state.isLoading,
        name: food.name,
        addButton: () async {
          final success = await manager.addFoodAndMenuWithImage(food, categoryId, type.name);
          if (context.mounted) context.router.pop();
          if (success) {
            _showInfoDialog(context);
          }
        },
        protein: MetricsHelper.getMetricValue(metrics, MetricType.protein),
        oil: MetricsHelper.getMetricValue(metrics, MetricType.fat),
        carbohydrates: MetricsHelper.getMetricValue(metrics, MetricType.carb),
        calories: MetricsHelper.getMetricValue(metrics, MetricType.kcal),
      ),
    );
  }

  void openCreatorWithSpeech(BuildContext context, AddMealsManager manager, List<ScannerFood> foods) {
    context.showAppBottomSheet(
      child: FoodCreatorWithSpeech(
        isLoading: manager.state.isLoading,
        meals: foods
            .map((e) => '${e.name} - ${MetricsHelper.getMetricValue(e.metrics, MetricType.kcal)} ${Strings.kcal}')
            .toList(),
        onAdd: () async {
          bool allSucceeded = true;
          for (final food in foods) {
            final success = await manager.addFoodAndMenuWithImage(food, categoryId, type.name);
            if (!success) {
              allSucceeded = false;
            }
          }
          if (context.mounted) {
            context.router.pop();
            if (allSucceeded) {
              _showInfoDialog(context);
            }
          }
        },
      ),
    );
  }

  Future<void> openCameraPage(BuildContext context, AddMealsManager manager) async {
    final imagePath = await context.pushRoute<String>(
      UniversalCameraRoute(
        title: Strings.scanning,
        subtitle: Strings.placeTheFoodInTheDesignatedAreaAndTakeAPicture,
        bottomText: Strings.food,
        useFrontCamera: false,
        onImageCaptured: (imagePath) async => context.router.pop(imagePath),
      ),
    );
    if (imagePath == null || !context.mounted) return;

    await context.pushRoute<bool>(
      UniversalProgressRoute(
        title: Strings.caloraAi,
        description: Strings.theDataInTheImageIsBeingProcessedWeWillAnnounceTheResultsSoon,
        steps: [
          Strings.theCompositionOfTheFoodIsBeingDetermined,
          Strings.theAmountOfFoodIsMeasured,
          Strings.theCalorieContentOfTheFoodIsBeingMeasured,
        ],
        apiCall: () => manager.getScannerFood(imagePath, categoryId),
      ),
    );

    if (context.mounted) {
      final scannedFoods = manager.state.scannedFoods;
      if (scannedFoods.isEmpty) {
        CustomSnackBar.show(context, 'No food found in image');
        return;
      }
      if (scannedFoods.length == 1) {
        openCreatorWithImage(context, manager, scannedFoods.first);
      } else {
        openCreatorWithSpeech(context, manager, scannedFoods);
      }
    }
  }

  void openSpeechPage(BuildContext context, AddMealsManager manager) {
    context.showAppBottomSheet(
      child: ModernVoiceRecorder(
        onFinished: (value) async {
          await context.pushRoute(
            UniversalProgressRoute(
              description: Strings.theInformationInYourVoicemailIsBeingAnalyzed,
              title: Strings.addByVoice,
              steps: [
                Strings.theCompositionOfTheFoodIsBeingDetermined,
                Strings.theAmountOfFoodIsMeasured,
                Strings.theCalorieContentOfTheFoodIsBeingMeasured,
              ],
              apiCall: () => manager.getScannerFoodByVoice(value, categoryId),
            ),
          );
          context.router.pop();
          if (context.mounted) {
            final scannedFoods = manager.state.scannedFoodsByVoice;
            if (scannedFoods.isEmpty) {
              CustomSnackBar.show(context, 'No food found in voice');
              return;
            }
            if (scannedFoods.length == 1) {
              openCreatorWithImage(context, manager, scannedFoods.first);
            } else {
              openCreatorWithSpeech(context, manager, scannedFoods);
            }
          }
        },
      ),
    );
  }

  Widget buildActionCard({
    required BuildContext context,
    Widget? icon,
    required String text,
    Color? textColor,
    VoidCallback? onTap,
    bool useGradient = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: useGradient ? null : context.colors.backgroundElevation,
            gradient: useGradient
                ? RadialGradient(
                    center: const Alignment(1.2, 0.5),
                    radius: 1.3,
                    colors: [context.colors.honeydew, context.colors.mintGreen],
                    stops: const [0.0, 1.0],
                  )
                : null,
          ),
          child: Column(
            spacing: 8,
            children: [if (icon != null) icon, text.text(14, 16, 600).c(textColor ?? context.colors.textWhite)],
          ),
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.colors.lightGreen,
            ),
            child: Assets.icons.twoDone.svg(),
          ),
          content: Strings.yourDataHasBeenSaved
              .text(16, 20, 400)
              .c(context.colors.textStrong)
              .copyWith(textAlign: TextAlign.center),
          actions: [
            Center(
              child: Button(
                onPressed: () {
                  dialogContext.pop();
                  context.pop(true);
                },
                text: Strings.close,
                textColor: context.colors.textStrong,
                type: ButtonType.secondary,
              ),
            ),
          ],
        );
      },
    );
  }
}
