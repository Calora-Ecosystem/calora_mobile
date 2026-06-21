import 'package:calora/domain/model/meal/food/food_models.dart'
    show ScannerFood;
import 'package:calora/domain/model/meal/food_request/food_request.dart';
import 'package:calora/domain/model/meal/menu/menu_info.dart';
import 'package:calora/domain/model/pagination/pagination_query.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class CaloriesApi {
  final Dio _dio;

  CaloriesApi(this._dio);

  Future<Response> getSummary(DateTime date) {
    return _dio.get(
      'food/summary',
      queryParameters: {'date': date.toIso8601String()},
    );
  }

  Future<Response> getFoodCategory() {
    return _dio.get('food/categories');
  }

  /// Paginated `/food` listing — supports all backend flags plus the
  /// `FilteringExpression` array (e.g. `categoryId==12`, `name$$mas`).
  ///
  /// Dio's default `ListFormat.multi` serializes the
  /// `filteringExpression` list as repeated `FilteringExpression=...`
  /// query params, matching the backend contract.
  Future<Response> fetchFoodsPaged({
    required PaginationQuery query,
    bool? latest,
    bool? isUserFood,
    bool? isFavourite,
  }) {
    final params = <String, dynamic>{
      if (latest != null) 'Latest': latest,
      if (isUserFood != null) 'IsUserFood': isUserFood,
      if (isFavourite != null) 'IsFavourite': isFavourite,
      ...query.toJson(),
    }..removeWhere((_, v) => v == null);

    return _dio.get('food', queryParameters: params);
  }

  Future<Response> addFood(FoodRequest food) {
    return _dio.post('food', data: food.toJson());
  }

  Future<Response> fetchFoodById(int id) {
    return _dio.get('food/$id');
  }

  Future<Response> fetchMenuItem(DateTime date, String menu) {
    return _dio.get(
      'food/menu',
      queryParameters: {'date': date.toIso8601String(), 'menu': menu},
    );
  }

  Future<void> saveMenuItem(MenuInfo item) {
    return _dio.post('food/menu', data: item.toJson());
  }

  /// Updates a user-owned food (name + metrics). Backend: `PUT /food/{foodId}`.
  Future<Response> updateFood(int foodId, FoodRequest food) {
    return _dio.put('food/$foodId', data: food.toJson());
  }

  /// Removes a single logged entry from the daily menu.
  /// Backend: `DELETE /food/menu/{itemId}`.
  Future<void> deleteMenuItem(int itemId) {
    return _dio.delete('food/menu/$itemId');
  }

  Future<void> addFavourite(int id) {
    return _dio.post('food/favourites/toggle/$id');
  }

  Future<List<ScannerFood>> getScannerFood(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: filePath.split('/').last,
      ),
    });

    final response = await _dio.post('food/recognization', data: formData);

    final List content = response.data['content'] ?? [];

    return content.map((e) => ScannerFood.fromJson(e)).toList();
  }

  Future<List<ScannerFood>> getScannerFoodByVoice(String audioPath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        audioPath,
        filename: audioPath.split('/').last,
        contentType: MediaType('audio', 'mpeg'),
      ),
    });

    final response = await _dio.post('food/recognization', data: formData);

    final List content = response.data['content'] ?? [];

    return content.map((e) => ScannerFood.fromJson(e)).toList();
  }
}
