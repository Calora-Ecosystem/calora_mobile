import 'package:calora/common/base/profile_store.dart';
import 'package:calora/common/extensions/assets_extension.dart';
import 'package:calora/common/extensions/foods_extension.dart';
import 'package:calora/domain/model/meal/food/food_models.dart';
import 'package:calora/domain/model/meal/food_request/food_request.dart';
import 'package:calora/domain/model/meal/meal_type_data.dart';
import 'package:calora/domain/model/meal/menu/menu_info.dart';
import 'package:calora/domain/repo/calories/calories_repo.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

import 'package:calora/presentation/meals/add/management/add_meals_management.dart';

@injectable
class AddMealsManager extends Manager<AddMealsState, AddMealsEffect> {
  final CaloriesRepo _repo;

  AddMealsManager(this._repo) : super(const AddMealsState());

  void fetchFoodCategory() {
    _repo.fetchFoodCategory().handle(
      onStart: () => emit(state.copyWith(isMealCategory: true)),
      onData: (categories) => emit(
        state.copyWith(mealCategories: categories, isMealCategory: false),
      ),
      onDone: () => emit(state.copyWith(isMealCategory: false)),
      onError: (error) => emit(state.copyWith(isMealCategory: false)),
    );
  }

  void fetchFavouriteFoods() {
    _repo.getFavouriteFoods().handle(
      onStart: () => emit(state.copyWith(isFavourite: true)),
      onData: (foods) =>
          emit(state.copyWith(favouriteFoods: foods, isFavourite: false)),
      onDone: () => emit(state.copyWith(isFavourite: false)),
      onError: (error) => emit(state.copyWith(isFavourite: false)),
    );
  }

  Future<bool> saveMenuItem(MenuInfo item) async {
    bool success = false;
    await _repo
        .saveMenuItem(item)
        .handle(
          onStart: () => emit(state.copyWith(isLoading: true)),
          onData: (_) {
            success = true;
          },
          onDone: () => emit(state.copyWith(isLoading: false)),
          onError: (error) {
            success = false;
            emit(state.copyWith(isLoading: false));
          },
        );
    return success;
  }

  void addFavourite(int id) {
    _repo
        .addFavourite(id)
        .handle(
          onStart: () => emit(state.copyWith(isLoading: true)),
          onDone: () => emit(state.copyWith(isLoading: false)),
          onError: (error) => emit(state.copyWith(isLoading: false)),
        );
  }

  void fetchUserFoods() {
    _repo.fetchUserFoods().handle(
      onStart: () => emit(state.copyWith(isLoading: true)),
      onData: (foods) =>
          emit(state.copyWith(userFoods: foods, isLoading: false)),
      onDone: () => emit(state.copyWith(isLoading: false)),
      onError: (error) => emit(state.copyWith(isLoading: false)),
    );
  }

  Future<List<ScannerFood>> getScannerFood(
    String filePath,
    int categoryId,
  ) async {
    List<ScannerFood> scannedFood = [];
    await _repo
        .getScannerFood(filePath)
        .handle(
          onStart: () => emit(state.copyWith(isLoading: true)),
          onData: (data) {
            emit(state.copyWith(scannedFoods: data, isLoading: false));
            scannedFood = data;
          },
          onDone: () => emit(state.copyWith(isLoading: false)),
          onError: (error) => emit(state.copyWith(isLoading: false)),
        );

    return scannedFood;
  }

  Future<List<ScannerFood>> getScannerFoodByVoice(
    String filePath,
    int categoryId,
  ) async {
    List<ScannerFood> scannedFood = [];
    await _repo
        .getScannerFood(filePath)
        .handle(
          onStart: () => emit(state.copyWith(isLoading: true)),
          onData: (data) {
            emit(state.copyWith(scannedFoodsByVoice: data, isLoading: false));
            scannedFood = data;
          },
          onDone: () => emit(state.copyWith(isLoading: false)),
          onError: (error) => emit(state.copyWith(isLoading: false)),
        );

    return scannedFood;
  }

  void fetchLatestFood() {
    _repo
        .fetchFoods(true)
        .handle(
          onStart: () => emit(state.copyWith(isLatest: true)),
          onData: (foods) =>
              emit(state.copyWith(latestFoods: foods, isLatest: false)),
          onDone: () => emit(state.copyWith(isLatest: false)),
          onError: (error) => emit(state.copyWith(isLatest: false)),
        );
  }

  Future<bool> addFoodAndMenuWithImage(
    ScannerFood food,
    int categoryId,
    String menu,
  ) async {
    final userId = await profileStore.getUserId() ?? 0;
    final foodRequest = food.toFoodRequest(
      categoryId: categoryId,
      userId: userId,
      coverUrl: abstractImageUrl,
    );
    final addedFoodId = await addFood(foodRequest);
    if (addedFoodId != null) {
      return saveMenuItem(
        MenuInfo(
          menu: menu,
          date: DateTime.now(),
          foodId: addedFoodId,
          weightInGr: 400,
        ),
      );
    }
    return false;
  }

  Future<bool> addFoodAndMenuWithVoice(int categoryId, String menu) async {
    final userId = await profileStore.getUserId();
    final List<FoodRequest> foodRequests = state.scannedFoodsByVoice
        .map(
          (e) => e.toFoodRequest(
            categoryId: categoryId,
            userId: userId ?? 0,
            coverUrl: abstractImageUrl,
          ),
        )
        .toList();
    for (int i = 0; i < foodRequests.length; i++) {
      final addedFoodId = await addFood(foodRequests[i]);
      if (addedFoodId == null) return false;
      final success = await saveMenuItem(
        MenuInfo(
          menu: menu,
          date: DateTime.now(),
          foodId: addedFoodId,
          weightInGr: 400,
        ),
      );
      if (!success) return false;
    }
    return true;
  }

  Future<int?> addFood(FoodRequest food) async {
    int? foodId;
    await _repo
        .addFood(food)
        .handle(
          onStart: () => emit(state.copyWith(isLoading: true)),
          onData: (id) {
            foodId = id;
            emit(state.copyWith(addedFoodId: id, isLoading: false));
          },
          onDone: () => emit(state.copyWith(isLoading: false)),
          onError: (error) {
            emit(state.copyWith(isLoading: false));
            foodId = null;
          },
        );
    return foodId;
  }

  void fetchSearchFood(String name) {
    _repo
        .fetchSearchFood(name)
        .handle(
          onStart: () => emit(state.copyWith(isSearch: true)),
          onData: (foods) =>
              emit(state.copyWith(searchFoods: foods, isSearch: false)),
          onDone: () => emit(state.copyWith(isSearch: false)),
          onError: (error) => emit(state.copyWith(isSearch: false)),
        );
  }

  void onSearchChanged(String text) {
    final query = text.trim();

    if (query.isEmpty) {
      emit(
        state.copyWith(isSearchMode: false, isSearch: false, searchFoods: []),
      );
      return;
    }

    if (query.length >= 3) {
      emit(state.copyWith(isSearchMode: true));
      fetchSearchFood(query);
    } else {
      emit(
        state.copyWith(isSearchMode: true, isSearch: false, searchFoods: []),
      );
    }
  }

  void openDishesPage(MealTypeData meal) {
    publish(AddMealsEffect.openDishesPage(meal));
  }

  void openAboutPage(FoodModel food, bool isFavourite) {
    publish(AddMealsEffect.openAboutPage(food, isFavourite));
  }

  void onToggleChanged(int index) {
    emit(state.copyWith(selectedToggleIndex: index));

    switch (index) {
      case 0:
        fetchFoodCategory();
        break;

      case 1:
        fetchLatestFood();
        break;

      case 2:
        fetchUserFoods();
        break;

      case 3:
        fetchFavouriteFoods();
        break;
    }
  }
}
