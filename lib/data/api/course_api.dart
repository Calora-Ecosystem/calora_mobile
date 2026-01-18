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

  Future<Response> getLessonById(int courseId, String level) async {
    return _dio.get('/workouts', queryParameters: {'courseId': courseId, 'level': level});
  }

  Future<void> updateVideoCourseFinished(int id) async {
    await _dio.put('/lessons/finish/${id}');
  }

  Future<Response> getExercisesByWorkoutId(int id) async {
    return _dio.get('/exercises', queryParameters: {'workoutId': id});
  }

  Future<void> finishedExercises(int id) async {
    await _dio.put('/exercises/finish/${id}');
  }
}
