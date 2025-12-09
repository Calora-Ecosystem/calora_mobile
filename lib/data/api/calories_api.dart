import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class CaloriesApi {
  final Dio _dio;

  CaloriesApi(this._dio);
}
