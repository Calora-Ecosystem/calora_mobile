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

    // Cancel qilish oldingi timer
    _debounce?.cancel();

    if (text.isEmpty) {
      // Agar text bo'sh bo'lsa darhol search mode'dan chiqish
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
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: Strings.searchForFoodOrProduct,
                  hintStyle: TextStyle(
                    color: context.colors.textSub,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 0.8,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.colors.strokeSoft, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.colors.blue, width: 1.5),
                  ),
                ),
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
                Expanded(
                  child: Builder(
                    builder: (_) {
                      if (state.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state.selectedToggleIndex == 3) {
                        return FavouriteFoodGrid(
                          foods: state.favouriteFoods,
                          onFoodSelected: (food) => manager.openAboutPage(food, food.isFavourite),
                        );
                      }
                      if (state.selectedToggleIndex == 1) {
                        return FavouriteFoodGrid(
                          foods: state.latestFoods,
                          onFoodSelected: (food) => manager.openAboutPage(food, food.isFavourite),
                        );
                      }
                      if (state.selectedToggleIndex == 2) {
                        return FavouriteFoodGrid(
                          foods: state.userFoods,
                          onFoodSelected: (food) => manager.openAboutPage(food, food.isFavourite),
                        );
                      }
                      return MealTypeGrid(
                        mealTypes: state.mealCategories,
                        onMealTypeSelected: (meal) => manager.openDishesPage(meal),
                      );
                    },
                  ),
                ),
              ],
              if (state.isSearchMode)
                Expanded(
                  child: Builder(
                    builder: (_) {
                      if (state.isSearch) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return FavouriteFoodGrid(
                        foods: state.searchFoods,
                        onFoodSelected: (food) => manager.openAboutPage(food, food.isFavourite),
                      );
                    },
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
      initialChildSize: 0.45,
      minChildSize: 0.2,
      maxChildSize: 0.5,
    );
  }

  void openCreatorWithImage(BuildContext context, AddMealsManager manager, ScannerFood food) {
    final metrics = food.metrics;
    context.showAppBottomSheet(
      child: FoodCreatorWithImage(
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
      initialChildSize: 0.55,
      minChildSize: 0.2,
      maxChildSize: 0.7,
    );
  }

  void openCreatorWithSpeech(BuildContext context, AddMealsManager manager, List<ScannerFood> foods) {
    context.showAppBottomSheet(
      child: FoodCreatorWithSpeech(
        meals: foods
            .map((e) => '${e.name} - ${MetricsHelper.getMetricValue(e.metrics, MetricType.kcal)} ${Strings.kcal}')
            .toList(),
        onAdd: () async {
          final success = await manager.addFoodAndMenuWithVoice(categoryId, type.name);
          context.router.pop();
          if (success) {
            _showInfoDialog(context);
          }
        },
      ),
      initialChildSize: 0.55,
      minChildSize: 0.2,
      maxChildSize: 0.6,
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
      initialChildSize: 0.5,
      minChildSize: 0.2,
      maxChildSize: 0.5,
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
          if (context.mounted) {
            context.router.pop();
            final scannedFoods = manager.state.scannedFoodsByVoice;
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
          content: Strings.yourDataHasBeenSavedSuccessfully
              .text(16, 20, 400)
              .c(context.colors.textStrong)
              .copyWith(textAlign: TextAlign.center),
          actions: [
            Center(
              child: Button(
                onPressed: () => dialogContext.pop(),
                text: Strings.close,
                textColor: context.colors.textStrong,
                type: Type.secondary,
              ),
            ),
          ],
        );
      },
    );
  }
}
