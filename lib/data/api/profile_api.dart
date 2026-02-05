import 'package:calora/domain/model/norms/daily_norms_info.dart';
import 'package:calora/domain/model/norms/norms.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class ProfileApi {
  final Dio _dio;

  ProfileApi(this._dio);

  Future<Response> getProfileMe() async {
    return _dio.get('/users/me');
  }

  Future<Response> getProfileExtras() async {
    return _dio.get('/users/extras');
  }

  Future<Response> getTargetWeight() async {
    return _dio.get('/users/norms', queryParameters: {'metrics': 'Weight'});
  }

  Future<Response> updateProfile(Map<String, dynamic> data) async {
    return _dio.post('/users/extras', data: data);
  }

  Future<DailyNormsInfo> getDailyNorms() async {
    final response = await _dio.get('/users/norms');

    final data = response.data;
    final List content = data['content'];

    double calories = 0;
    double protein = 0;
    double fat = 0;
    double carbs = 0;
    double water = 0;
    double steps = 0;

    for (final item in content) {
      final metric = item['metric']?.toString() ?? '';
      final value = (item['value'] ?? 0).toDouble();

      switch (metric) {
        case 'Kcal':
          calories = value;
          break;
        case 'Protein':
          protein = value;
          break;
        case 'Fat':
          fat = value;
          break;
        case 'Carb':
          carbs = value;
          break;
        case 'Water':
          water = value;
          break;
        case 'Step':
          steps = value;
          break;
      }
    }

    return DailyNormsInfo(calories: calories, protein: protein, fat: fat, carbs: carbs, water: water, steps: steps);
  }

  Future<Response> updateSingleNorm(NormsRequest request) async {
    return _dio.post('/users/norms', data: request.toJson());
  }

  Future<void> logout() async {
    await _dio.get('/auth/logout');
  }
}
