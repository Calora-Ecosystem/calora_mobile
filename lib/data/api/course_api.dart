import 'package:calora/data/store/common/common_store.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class CourseApi {
  final Dio _dio;
  final CommonStore _commonStore;

  CourseApi(this._dio, this._commonStore);

  Future<Response> getCourse(String gender) async {
    return _dio.get('/course', queryParameters: {'Gender': gender});
  }

  Future<Response> getLessonsById(int id) async {
    return _dio.get('/lessons', queryParameters: {'courseId': id});
  }
}
