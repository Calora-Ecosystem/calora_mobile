import 'dart:async';

import 'package:calora/common/base/profile_store.dart';
import 'package:calora/common/extensions/assets_extension.dart';
import 'package:calora/common/extensions/foods_extension.dart';
import 'package:calora/common/service/pagination_service.dart';
import 'package:calora/common/util/api_error.dart';
import 'package:calora/domain/model/meal/food/food_models.dart';
import 'package:calora/domain/model/meal/food_request/food_request.dart';
import 'package:calora/domain/model/meal/meal_type_data.dart';
import 'package:calora/domain/model/meal/menu/menu_info.dart';
import 'package:calora/domain/model/pagination/paginated_response.dart';
import 'package:calora/domain/model/pagination/pagination_query.dart';
import 'package:calora/domain/repo/calories/calories_repo.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

import 'package:calora/presentation/meals/add/management/add_meals_management.dart';

@injectable
class AddMealsManager extends Manager<AddMealsState, AddMealsEffect> {
  final CaloriesRepo _repo;

  AddMealsManager(this._repo) : super(const AddMealsState()) {
    foodPaginator = PaginationService<FoodModel>(fetchData: _fetchActiveTab);
  }

  /// Single paginator for the food grid. Its `fetchData` closure
  /// dispatches by `state.activeTab` + `state.searchQuery` so we can
  /// reuse one infinite-scroll controller across all tabs and the
  /// search overlay. Switching tab / search → `refresh()` restarts
  /// pagination from `Skip=0`.
  late final PaginationService<FoodModel> foodPaginator;

  Timer? _searchDebounce;
  static const _searchDebounceDelay = Duration(milliseconds: 350);

  // ── Paginator dispatch ──────────────────────────────────────────────

  Future<PaginatedResponse<FoodModel>> _fetchActiveTab(
    PaginationQuery query,
  ) async {
    final filters = <String>[
      ...?query.filteringExpression,
    ];

    switch (state.activeTab) {
      case FoodTab.search:
        // Search filter is supplied via `updateFilter` (see
        // `onSearchChanged`). Backend supports combining with category
        // / boolean flags should we ever need it.
        return _repo.fetchFoodsPaged(
          query: query.copyWith(filteringExpression: filters),
        );

      case FoodTab.latest:
        return _repo.fetchFoodsPaged(query: query, latest: true);

      case FoodTab.userFoods:
        return _repo.fetchFoodsPaged(query: query, isUserFood: true);

      case FoodTab.favourites:
        return _repo.fetchFoodsPaged(query: query, isFavourite: true);

      case FoodTab.categories:
        // Not a food list; should never be hit while the paginator is
        // active. Return an empty page defensively.
        return const PaginatedResponse<FoodModel>(content: [], total: 0);
    }
  }

  // ── Categories (top-level "All Dishes" tab) ─────────────────────────

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

  // ── Tab + search routing ────────────────────────────────────────────

  void onToggleChanged(int index) {
    final tab = switch (index) {
      0 => FoodTab.categories,
      1 => FoodTab.latest,
      2 => FoodTab.userFoods,
      3 => FoodTab.favourites,
      _ => FoodTab.categories,
    };

    // Switching tabs clears any in-flight search so the user gets the
    // expected results for that tab.
    emit(state.copyWith(activeTab: tab, searchQuery: ''));

    if (tab == FoodTab.categories) {
      fetchFoodCategory();
    } else {
      foodPaginator.updateFilter(null);
    }
  }

  /// Called from the search TextField. Debounces the typed query
  /// (350 ms) before hitting the backend with
  /// `FilteringExpression=name$$<query>`.
  void onSearchChanged(String text) {
    final query = text.trim();
    _searchDebounce?.cancel();

    if (query.isEmpty) {
      // Leaving search overlay: restore the previously selected tab if
      // it was a food tab, otherwise the categories grid.
      if (state.activeTab == FoodTab.search) {
        emit(state.copyWith(
          activeTab: FoodTab.categories,
          searchQuery: '',
        ));
        fetchFoodCategory();
      } else {
        emit(state.copyWith(searchQuery: ''));
      }
      return;
    }

    emit(state.copyWith(searchQuery: query, activeTab: FoodTab.search));

    if (query.length < 3) {
      // Show the search overlay but don't hit the backend yet — short
      // queries get noisy and the backend matches a min length anyway.
      foodPaginator.updateFilter(null);
      return;
    }

    _searchDebounce = Timer(_searchDebounceDelay, () {
      foodPaginator.updateFilter(['name\$\$$query']);
    });
  }

  // ── Mutations (unchanged) ───────────────────────────────────────────

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
            emit(
              state.copyWith(
                isLoading: false,
                addErrorMessage: apiErrorMessage(error),
              ),
            );
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

  /// Creates a food from explicit (user-edited) values and logs it to the
  /// menu. Used when the user corrects AI scan/voice results before adding.
  Future<bool> addCustomFoodAndMenu({
    required String name,
    required int calories,
    required double protein,
    required double fat,
    required double carbs,
    required int weightInGr,
    required String menu,
    required DateTime date,
    int? categoryId,
  }) async {
    final userId = await profileStore.getUserId() ?? 0;
    // The nutrition above describes this exact portion, so the food's base
    // weight and the logged amount are both the AI-estimated weight. Fall
    // back to the 400g neutral base only when the AI gave no weight.
    final resolvedWeight = weightInGr > 0 ? weightInGr : 400;
    final request = FoodRequest(
      categoryId: categoryId,
      name: FoodName(uz: name, ru: name, eng: name, cyrl: name),
      coverUrl: abstractImageUrl,
      metrics: [
        Metric(userId: 0, metric: MetricType.kcal.name, value: calories),
        Metric(userId: 0, metric: MetricType.protein.name, value: protein),
        Metric(userId: 0, metric: MetricType.fat.name, value: fat),
        Metric(userId: 0, metric: MetricType.carb.name, value: carbs),
        Metric(userId: 0, metric: MetricType.weight.name, value: resolvedWeight),
      ],
      userId: userId,
    );
    final addedFoodId = await addFood(request);
    if (addedFoodId != null) {
      return saveMenuItem(
        MenuInfo(
          menu: menu,
          date: date,
          foodId: addedFoodId,
          weightInGr: resolvedWeight,
        ),
      );
    }
    return false;
  }

  Future<bool> addFoodAndMenuWithImage(
    ScannerFood food,
    String menu,
    DateTime date,
  ) async {
    final userId = await profileStore.getUserId() ?? 0;
    final foodRequest = food.toFoodRequest(
      userId: userId,
      coverUrl: abstractImageUrl,
    );
    final addedFoodId = await addFood(foodRequest);
    if (addedFoodId != null) {
      return saveMenuItem(
        MenuInfo(
          menu: menu,
          date: date,
          foodId: addedFoodId,
          weightInGr: food.weight > 0 ? food.weight : 400,
        ),
      );
    }
    return false;
  }

  Future<bool> addFoodAndMenuWithVoice(String menu, DateTime date) async {
    final userId = await profileStore.getUserId();
    final List<ScannerFood> foods = state.scannedFoodsByVoice;
    for (final food in foods) {
      final addedFoodId = await addFood(
        food.toFoodRequest(userId: userId ?? 0, coverUrl: abstractImageUrl),
      );
      if (addedFoodId == null) return false;
      final success = await saveMenuItem(
        MenuInfo(
          menu: menu,
          date: date,
          foodId: addedFoodId,
          weightInGr: food.weight > 0 ? food.weight : 400,
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
            emit(
              state.copyWith(
                isLoading: false,
                addErrorMessage: apiErrorMessage(error),
              ),
            );
            foodId = null;
          },
        );
    return foodId;
  }

  void openDishesPage(MealTypeData meal) {
    publish(AddMealsEffect.openDishesPage(meal));
  }

  void openAboutPage(FoodModel food, bool isFavourite) {
    publish(AddMealsEffect.openAboutPage(food, isFavourite));
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    foodPaginator.dispose();
    return super.close();
  }
}
