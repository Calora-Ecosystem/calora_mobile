import 'package:calora/domain/model/calories/calories_data.dart';
import 'package:calora/domain/model/meal/food/food_models.dart';
import 'package:calora/domain/model/meal/food_request/food_request.dart';
import 'package:calora/domain/model/meal/meal_type_data.dart';
import 'package:calora/domain/model/meal/menu/menu_info.dart';
import 'package:calora/domain/model/meal/menu/menu_item.dart';
import 'package:calora/domain/model/pagination/paginated_response.dart';
import 'package:calora/domain/model/pagination/pagination_query.dart';
import 'package:calora/domain/model/summary/summary_request.dart';

abstract class CaloriesRepo {
  Future<SummaryResult> fetchSummary(DateTime date);

  Future<SummaryRequest> getSummary(DateTime date);

  Future<List<MealTypeData>> fetchFoodCategory();

  Future<List<MenuItem>> fetchMenuItem(DateTime date, String menu);

  Future<FoodModel> fetchFoodById(int id);

  Future<void> saveMenuItem(MenuInfo item);

  Future<void> updateFood(int foodId, FoodRequest food);

  Future<void> deleteMenuItem(int itemId);

  Future<void> addFavourite(int id);

  Future<int> addFood(FoodRequest food);

  Future<List<ScannerFood>> getScannerFood(String filePath);

  Future<List<ScannerFood>> getScannerFoodByVoice(String filePath);

  /// Uploads a scanned food photo and returns its persisted relative
  /// URL (used as the food's `coverUrl`), or `null` if the upload failed.
  Future<String?> uploadFoodImage(String filePath);

  /// Paginated food listing. Pass any of [latest], [isUserFood],
  /// [isFavourite] to scope the result; pass `categoryId==<id>` or
  /// `name$$<query>` strings through [PaginationQuery.filteringExpression]
  /// for category filtering / search.
  Future<PaginatedResponse<FoodModel>> fetchFoodsPaged({
    required PaginationQuery query,
    bool? latest,
    bool? isUserFood,
    bool? isFavourite,
  });
}
