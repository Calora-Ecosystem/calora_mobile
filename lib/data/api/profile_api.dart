import 'package:calora/domain/model/norms/daily_norms_info.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class ProfileApi {
  final Dio _dio;

  ProfileApi(this._dio);

  Future<Response> getProfile() {
    return _dio.get('/users/me');
    // return ProfileRequest(
    //   height: 180,
    //   gender: 'Male',
    //   name: 'Nodir',
    //   email: 'hasanovnodir2005@gmail.com',
    //   bmi: 38.5,
    //   targetWeight: 70,
    //   weight: 88,
    //   userId: 'a424fjie4934dvjk',
    // );
  }

  Future<DailyNormsInfo> getDailyNorms() async {
    return DailyNormsInfo(
      calories: 123,
      protein: 122,
      fat: 1212,
      carbs: 2313,
      water: 3213,
      steps: 23133,
    );
  }

  Future<Response> updateDailyNorms(DailyNormsInfo dailyNormsInfo) {
    return _dio.post('/users/norms', data: dailyNormsInfo.toJson());
  }

  Future<void> logout() async {
    print('Log out');
  }
}
