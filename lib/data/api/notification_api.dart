import 'dart:developer'; // Import for log function
import 'package:calora/domain/model/reminder/reminder_request.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@injectable
class NotificationApi {
  final Dio _dio;

  NotificationApi(this._dio);

  Future<List<ReminderRequest>> getReminders() async {
    final response = await _dio.get('/reminder');
    final List<ReminderRequest> data = ReminderRequest.fromJsonList((response.data as Map<String, dynamic>)['content']);
    return data;
  }

  Future<ReminderRequest> updateReminder(ReminderRequest request) async {
    final requestPayload = request.toJson()..remove('id');
    log('NotificationApi: Sending updateReminder request with payload: $requestPayload');
    final response = await _dio.post('/reminder', data: requestPayload);
    log('NotificationApi: Received updateReminder response data: ${response.data}');
    final Map<String, dynamic> contentData = response.data['content'];
    return ReminderRequest.fromJson(contentData);
  }

  Future<void> deleteReminder(int id) async {
    await _dio.delete('/reminder/$id');
  }
}
