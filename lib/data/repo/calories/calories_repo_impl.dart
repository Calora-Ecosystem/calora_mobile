import 'package:calora/data/api/calories_api.dart';
import 'package:calora/domain/model/calories/calories_data.dart';
import 'package:calora/domain/model/meal/food/food_models.dart';
import 'package:calora/domain/model/meal/food_request/food_request.dart';
import 'package:calora/domain/model/meal/meal_type_data.dart';
import 'package:calora/domain/model/meal/menu/menu_info.dart';
import 'package:calora/domain/model/meal/menu/menu_item.dart';
import 'package:calora/domain/model/summary/summary_request.dart';
import 'package:calora/domain/repo/calories/calories_repo.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: CaloriesRepo)
class CaloriesRepoImpl extends CaloriesRepo {
  final CaloriesApi _api;

  CaloriesRepoImpl(this._api);

  @override
  Future<SummaryResult> fetchSummary(DateTime date) async {
    final response = await _api.getSummary(date);
    final content = SummaryRequest.fromJson(response.data['content']);

    final dailyCalories = DailyCalories(
      plan: content.kcalNorm.value.toDouble(),
      consumed: content.sumKcal.toDouble(),
      leftover: (content.kcalNorm.value - content.sumKcal).toDouble(),
    );

    final meals = MealType.values.map((mealType) {
      final key = mealType.name;
      final nutrientNorm = content.nutrientsNorm[key];
      final nutrient = content.nutrients[key];

      return MealData(
        max: nutrientNorm?.kcal.toDouble() ?? 0,
        value: nutrient?.kcal.toDouble() ?? 0,
        type: mealType,
        mass: nutrientNorm?.weight.toDouble() ?? 0,
        carbohydrates: nutrient?.carb.toDouble() ?? 0,
        proteins: nutrient?.protein.toDouble() ?? 0,
        oils: nutrient?.fat.toDouble() ?? 0,
      );
    }).toList();

    return SummaryResult(dailyCalories: dailyCalories, meals: meals);
  }

  @override
  Future<List<MealTypeData>> fetchFoodCategory() async {
    final response = await _api.getFoodCategory();
    final List list = response.data['content'];

    return list.map((e) => MealTypeData(id: e['id'], name: e['name'], imageUrl: e['coverUrl'])).toList();
  }

  @override
  Future<FoodModel> fetchFoodById(int id) async {
    final response = await _api.fetchFoodById(id);
    final data = response.data['content'];

    return FoodModel(
      id: data['id'],
      name: data['name'],
      description: data['description'],
      categoryId: data['categoryId'],
      categoryName: data['categoryName'],
      coverUrl: data['coverUrl'],
      metrics: (data['metrics'] as List).map((e) => Metric.fromJson(e)).toList(),
      isUserFood: data['isUserFood'] ?? false,
      isFavourite: data['isFavourite'] ?? false,
      userId: data['userId'],
    );
  }

  @override
  Future<List<FoodModel>> fetchFoods(bool latest) async {
    final response = await _api.fetchFoods(latest);
    final List list = response.data['content'];

    return list.map((e) {
      return FoodModel(
        id: e['id'],
        name: e['name'],
        categoryId: e['categoryId'],
        categoryName: e['categoryName'],
        coverUrl: e['coverUrl'],
        metrics: (e['metrics'] as List).map((m) => Metric.fromJson(m)).toList(),
        isUserFood: e['isUserFood'] ?? false,
        isFavourite: e['isFavourite'] ?? false,
      );
    }).toList();
  }

  @override
  Future<List<MenuItem>> fetchMenuItem(DateTime date, String menu) async {
    final response = await _api.fetchMenuItem(date, menu);
    final List list = response.data['content'];

    return list.map((e) {
      return MenuItem(
        weight: (e['weight'] as num).toDouble(),
        menu: e['menu'],
        date: DateTime.parse(e['date']),
        foodId: e['foodId'],
        foodName: e['foodName'],
        categoryId: e['categoryId'],
        categoryName: e['categoryName'],
        coverUrl: e['coverUrl'],
        metrics: (e['metrics'] as List).map((m) => Metric.fromJson(m)).toList(),
        userId: e['userId'],
      );
    }).toList();
  }

  @override
  Future<void> saveMenuItem(MenuInfo item) async {
    await _api.saveMenuItem(item);
  }

  @override
  Future<void> addFavourite(int id) async {
    await _api.addFavourite(id);
  }

  @override
  Future<int> addFood(FoodRequest food) async {
    final response = await _api.addFood(food);
    final data = response.data['content'];
    final int id = data['id'];
    return id;
  }

  @override
  Future<List<FoodModel>> getFavouriteFoods() async {
    final response = await _api.getFavouriteFoods();
    final List list = response.data['content'];

    return list.map((e) {
      return FoodModel(
        id: e['id'],
        name: e['name'],
        categoryId: e['categoryId'],
        categoryName: e['categoryName'],
        coverUrl: e['coverUrl'],
        metrics: (e['metrics'] as List).map((m) => Metric.fromJson(m)).toList(),
        isUserFood: e['isUserFood'] ?? false,
        isFavourite: e['isFavourite'] ?? false,
      );
    }).toList();
  }

  @override
  Future<List<ScannerFood>> getScannerFood(String filePath) async {
    final response = await _api.getScannerFood(filePath);
    return response;
  }

  @override
  Future<List<ScannerFood>> getScannerFoodByVoice(String filePath) async {
    final response = await _api.getScannerFoodByVoice(filePath);
    return response;
  }

  @override
  Future<SummaryRequest> getSummary(DateTime date) async {
    final response = await _api.getSummary(date);
    return SummaryRequest.fromJson(response.data['content']);
  }
}
