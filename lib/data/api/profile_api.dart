import 'package:calora/domain/model/norms/daily_norms_request.dart';
import 'package:calora/domain/model/profile/profile_request.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class ProfileApi {
  final Dio _dio;

  ProfileApi(this._dio);

  Future<ProfileRequest> getProfile() async {
    return ProfileRequest(
      name: 'Nodir',
      email: 'hasanovnodir2005@gmail.com',
      bmi: 38.5,
      targetWeight: 70,
      weight: 88,
      userId: 'a424fjie4934dvjk',
    );
  }

  Future<DailyNormsRequest> getDailyNorms() async {
    return DailyNormsRequest(
      calories: 123,
      protein: 122,
      fat: 1212,
      carbs: 2313,
      water: 3213,
      steps: 23133,
    );
  }

  Future<void> logout() async {
    print('Log out');
  }
}
