import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class NotificationApi {
  final Dio _dio;
  NotificationApi(this._dio);

  Future<Response> getNotifications({required int skip, required int take}) {
    return _dio.get('notifications', queryParameters: {'Skip': skip, 'Take': take});
  }

  Future<Response> getUnread() {
    return _dio.get('notifications/unread');
  }

  Future<Response> markAsRead(int notificationId) {
    return _dio.put('notifications/mark-as-read/$notificationId');
  }
}