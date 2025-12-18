import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class CaloriesApi {
  final Dio _dio;

  CaloriesApi(this._dio);

  Future<Response> getDailyCalories(DateTime date) {
    return _dio.get('/food/summary', queryParameters: {'date': date.toIso8601String()});
  }

  Future<Response> getFoodCategory() {
    return _dio.get('/food/categories');
  }

  Future<Response> fetchFoods() {
    return _dio.get('/food');
  }

  Future<Response> fetchFoodById(int id) {
    return _dio.get('/food/$id');
  }

  Future<Response> fetchMenuItem(DateTime date) {
    return _dio.get('/food/menu', queryParameters: {'date': date.toIso8601String()});
  }
}
