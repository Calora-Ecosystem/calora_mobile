import 'package:calora/domain/model/calories/calories_data.dart';
import 'package:calora/domain/model/meal/food/food_models.dart';
import 'package:calora/domain/model/meal/food_request/food_request.dart';
import 'package:calora/domain/model/meal/meal_type_data.dart';
import 'package:calora/domain/model/meal/menu/menu_info.dart';
import 'package:calora/domain/model/meal/menu/menu_item.dart';
import 'package:calora/domain/model/summary/summary_request.dart';

abstract class CaloriesRepo {
  Future<SummaryResult> fetchSummary(DateTime date);

  Future<SummaryRequest> getSummary(DateTime date);

  Future<List<MealTypeData>> fetchFoodCategory();

  Future<List<FoodModel>> fetchFoods(bool latest);

  Future<List<MenuItem>> fetchMenuItem(DateTime date, String menu);

  Future<FoodModel> fetchFoodById(int id);

  Future<void> saveMenuItem(MenuInfo item);

  Future<void> addFavourite(int id);

  Future<int> addFood(FoodRequest food);

  Future<List<FoodModel>> getFavouriteFoods();

  Future<List<ScannerFood>> getScannerFood(String filePath);

  Future<List<ScannerFood>> getScannerFoodByVoice(String filePath);

  Future<List<FoodModel>> fetchUserFoods();

  Future<List<FoodModel>> fetchSearchFood(String name);
}
