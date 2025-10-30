import 'package:calora/domain/model/norms/daily_norms_info.dart';
import 'package:calora/domain/model/notification/reminder_request.dart';
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
    return DailyNormsInfo(calories: 123, protein: 122, fat: 1212, carbs: 2313, water: 3213, steps: 23133);
  }

  Future<Response> updateDailyNorms(DailyNormsInfo dailyNormsInfo) {
    return _dio.post('/users/norms', data: dailyNormsInfo.toJson());
  }

  Future<void> logout() async {
    print('Log out');
  }

  Future<Response> getReminders() {
    return _dio.get('/reminder');
  }

  Future<Response> postReminders({required ReminderRequest reminder}) async {
    return _dio.post('/reminder', data: reminder.toJson());
  }

  Future<void> deleteReminder(int id) async {
    _dio.delete('/reminder/$id');
  }
}
