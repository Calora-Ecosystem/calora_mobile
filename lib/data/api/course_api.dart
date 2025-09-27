import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class CourseApi {
  final Dio _dio;

  CourseApi(this._dio);
}
