import 'package:calora/data/repo/calories/calories_repo_impl.dart';
import 'package:calora/domain/model/meal/food/food_models.dart';
import 'package:calora/domain/model/meal/meal_type_data.dart';
import 'package:calora/domain/model/meal/menu/menu_item.dart';

abstract class CaloriesRepo {
  Future<SummaryResult> fetchSummary(DateTime date);

  Future<List<MealTypeData>> fetchFoodCategory();

  Future<List<FoodListItem>> fetchFoods();

  Future<List<MenuItem>> fetchMenuItem(DateTime date);

  Future<FoodItem> fetchFoodById(int id);
}
