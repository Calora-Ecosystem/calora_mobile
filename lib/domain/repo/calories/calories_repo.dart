import 'package:calora/domain/model/calories/calories_data.dart';
import 'package:calora/domain/model/meal/dish/dish_data.dart';
import 'package:calora/domain/model/meal/meal_type_data.dart';

abstract class CaloriesRepo {
  Future<List<MealData>> getMeals();

  Future<DailyCalories> getCalories();

  Future<List<DishData>> getDishes(MealCategory category);
}
