import 'package:calora/domain/model/meal/food/food_models.dart' show ScannerFood;
import 'package:calora/domain/model/meal/food_request/food_request.dart';
import 'package:calora/domain/model/meal/menu/menu_info.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class CaloriesApi {
  final Dio _dio;

  CaloriesApi(this._dio);

  Future<Response> getSummary(DateTime date) {
    return _dio.get('/food/summary', queryParameters: {'date': date.toIso8601String()});
  }

  Future<Response> getFoodCategory() {
    return _dio.get('/food/categories');
  }

  Future<Response> fetchFoods(bool latest) {
    return _dio.get('/food', queryParameters: {'latest': latest});
  }

  Future<Response> addFood(FoodRequest food) {
    return _dio.post('/food', data: food.toJson());
  }

  Future<Response> fetchFoodById(int id) {
    return _dio.get('/food/$id');
  }

  Future<Response> fetchMenuItem(DateTime date, String menu) {
    return _dio.get('/food/menu', queryParameters: {'date': date.toIso8601String(), 'menu': menu});
  }

  Future<void> saveMenuItem(MenuInfo item) {
    return _dio.post('/food/menu', data: item.toJson());
  }

  Future<void> addFavourite(int id) {
    return _dio.post('/food/favourites/toggle/$id');
  }

  Future<Response> getFavouriteFoods() {
    return _dio.get('/food/favourites');
  }

  Future<List<ScannerFood>> getScannerFood(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: filePath.split('/').last,
      ),
    });

    final response = await _dio.post(
      '/food/recognization',
      data: formData,
    );

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

    final response = await _dio.post(
      '/food/recognization',
      data: formData,
    );

    final List content = response.data['content'] ?? [];

    return content.map((e) => ScannerFood.fromJson(e)).toList();
  }
}
