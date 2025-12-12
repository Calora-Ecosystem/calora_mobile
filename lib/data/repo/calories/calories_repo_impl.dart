import 'package:calora/data/api/calories_api.dart';
import 'package:calora/domain/model/calories/calories_data.dart';
import 'package:calora/domain/model/meal/food/food_models.dart';
import 'package:calora/domain/model/meal/meal_type_data.dart';
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
    final response = await _api.getDailyCalories(date);
    final summary = SummaryRequest.fromJson(response.data);
    final content = summary.content;

    final dailyCalories = DailyCalories(
      plan: content.kcalNorm.value.toDouble(),
      consumed: content.sumKcal.toDouble(),
      leftover: (content.kcalNorm.value - content.sumKcal).toDouble(),
    );

    final meals = MealType.values.map((mealType) {
      final key = _mealTypeToString(mealType);
      final nutrientNorm = content.nutrientsNorm[key];
      final nutrient = content.nutrients[key];
      return MealData(
        max: nutrientNorm?.kcal.toDouble() ?? 0,
        value: nutrient?.kcal.toDouble() ?? 0,
        type: mealType,
        mass: 300,
        carbohydrates: nutrient?.carb.toDouble() ?? 0,
        proteins: nutrient?.protein.toDouble() ?? 0,
        oils: nutrient?.fat.toDouble() ?? 0,
      );
    }).toList();

    return SummaryResult(dailyCalories: dailyCalories, meals: meals);
  }

  String _mealTypeToString(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snacks:
        return 'Snack';
    }
  }

  Future<List<MealTypeData>> fetchFoodCategory() async {
    final response = await _api.getFoodCategory();

    final List list = response.data['content'];

    return list.map((e) {
      return MealTypeData(name: e['name'], imageUrl: e['coverUrl'], id: e['id']);
    }).toList();
  }

  @override
  Future<FoodItem> fetchFoodById(int id) async {
    final response = await _api.fetchFoodById(id);
    final data = response.data['content'];
    return FoodItem(
      id: data['id'],
      name: data['name'],
      description: data['description'],
      categoryId: data['categoryId'],
      categoryName: data['categoryName'],
      coverUrl: data['coverUrl'],
      metrics: (data['metrics'] as List<dynamic>)
          .map((metric) => Metric.fromJson(metric as Map<String, dynamic>))
          .toList(),
      isUserFood: data['isUserFood'],
    );
  }

  @override
  Future<List<FoodListItem>> fetchFoods() async {
    final response = await _api.fetchFoods();
    final List list = response.data['content'];
    return list.map((e) {
      return FoodListItem(
        id: e['id'],
        name: e['name'],
        categoryId: e['categoryId'],
        categoryName: e['categoryName'],
        coverUrl: e['coverUrl'],
        metrics: (e['metrics'] as List<dynamic>)
            .map((metric) => Metric.fromJson(metric as Map<String, dynamic>))
            .toList(),
        isUserFood: e['isUserFood'],
      );
    }).toList();
  }

  @override
  Future<List<MenuItem>> fetchMenuItem(DateTime date) async {
    final response = await _api.fetchMenuItem(date);
    final List list = response.data['content'];
    return list.map((e) {
      return MenuItem(
        menu: e['menu'],
        date: DateTime.parse(e['date']),
        foodId: e['foodId'],
        foodName: e['foodName'],
        categoryId: e['categoryId'],
        categoryName: e['categoryName'],
        coverUrl: e['coverUrl'],
        metrics: (e['metrics'] as List<dynamic>)
            .map((metric) => Metric.fromJson(metric as Map<String, dynamic>))
            .toList(),
        userId: e['userId'],
      );
    }).toList();
  }
}

class SummaryResult {
  final DailyCalories dailyCalories;
  final List<MealData> meals;

  SummaryResult({required this.dailyCalories, required this.meals});
}
