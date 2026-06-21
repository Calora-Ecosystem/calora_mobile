import 'package:calora/common/base/profile_store.dart';
import 'package:calora/common/extensions/assets_extension.dart';
import 'package:calora/common/extensions/foods_extension.dart';
import 'package:calora/domain/model/calories/calories_data.dart';
import 'package:calora/domain/model/meal/food/food_models.dart';
import 'package:calora/domain/model/meal/food_request/food_request.dart';
import 'package:calora/domain/model/meal/menu/menu_info.dart';
import 'package:calora/domain/model/meal/menu/menu_item.dart';
import 'package:calora/domain/repo/calories/calories_repo.dart';
import 'package:calora/presentation/meals/management/meals_management.dart';
import 'package:injectable/injectable.dart' show injectable;
import 'package:management/management.dart';

@injectable
class MealsManager extends Manager<MealsState, MealsEffect> {
  final CaloriesRepo caloriesRepo;

  MealsManager(this.caloriesRepo) : super(const MealsState());

  void fetchMenuItem(DateTime date, MealType type) {
    caloriesRepo
        .fetchMenuItem(date, type.name)
        .handle(
          onStart: () => emit(state.copyWith(isLoading: true)),
          onData: (value) {
            emit(state.copyWith(menuItems: value, isLoading: false));
          },
          onDone: () => emit(state.copyWith(isLoading: false)),
          onError: (error) => emit(state.copyWith(isLoading: false)),
        );
  }

  MealData? getMealByType(MealType type, List<MealData> meals) {
    for (final meal in meals) {
      if (meal.type == type) return meal;
    }
    return null;
  }

  void fetchSummary(DateTime date, MealType type) {
    caloriesRepo
        .fetchSummary(date)
        .handle(
          onStart: () => emit(state.copyWith(isSummary: true)),
          onData: (result) {
            final meal = getMealByType(type, result.meals);
            emit(state.copyWith(meal: meal, isSummary: false));
          },
          onDone: () => emit(state.copyWith(isSummary: false)),
          onError: (error) => emit(state.copyWith(isSummary: false)),
        );
  }

  /// Edits a logged food's name + kcal/protein/fat/carb and refreshes.
  ///
  /// * For the user's own food we update it in place (`PUT /food/{id}`).
  /// * For a shared/category food (which can't be edited globally) we create
  ///   a personal copy and re-point the logged entry to it, so the change
  ///   only affects this user's diary.
  Future<void> updateFood(
    MenuItem item,
    String name,
    int calories,
    double protein,
    double fat,
    double carbs,
    DateTime date,
    MealType type,
  ) async {
    final foodId = item.foodId;
    if (foodId == null) return;
    final userId = await profileStore.getUserId() ?? 0;

    final request = FoodRequest(
      categoryId: item.categoryId,
      name: FoodName(uz: name, ru: name, eng: name, cyrl: name),
      coverUrl: item.coverUrl ?? abstractImageUrl,
      metrics: [
        Metric(userId: 0, metric: MetricType.kcal.name, value: calories),
        Metric(userId: 0, metric: MetricType.protein.name, value: protein),
        Metric(userId: 0, metric: MetricType.fat.name, value: fat),
        Metric(userId: 0, metric: MetricType.carb.name, value: carbs),
      ],
      userId: userId,
    );

    emit(state.copyWith(isLoading: true));
    try {
      final bool isOwnFood = item.userId != null;
      if (isOwnFood) {
        await caloriesRepo.updateFood(foodId, request);
      } else {
        // Create a personal copy and swap the logged entry over to it.
        final newFoodId = await caloriesRepo.addFood(request);
        await caloriesRepo.saveMenuItem(
          MenuInfo(
            menu: type.name,
            date: item.date ?? date,
            foodId: newFoodId,
            // 400g base keeps the entered values shown as-is (like manual foods).
            weightInGr: 400,
          ),
        );
        if (item.id != null) {
          await caloriesRepo.deleteMenuItem(item.id!);
        }
      }
      fetchMenuItem(date, type);
      fetchSummary(date, type);
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  /// Removes a single logged entry from the daily menu and refreshes.
  void deleteMenuItem(int itemId, DateTime date, MealType type) {
    caloriesRepo
        .deleteMenuItem(itemId)
        .handle(
          onStart: () => emit(state.copyWith(isLoading: true)),
          onData: (_) {
            fetchMenuItem(date, type);
            fetchSummary(date, type);
          },
          onError: (error) => emit(state.copyWith(isLoading: false)),
        );
  }

  void openAddMealPage() {
    publish(MealsEffect.openAddMealPage());
  }
}
