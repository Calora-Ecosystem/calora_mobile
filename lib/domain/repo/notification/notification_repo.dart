import 'package:calora/domain/model/notification/notificaiton_setting.dart';
import 'package:calora/domain/model/notification/notification.dart' as model;
import 'package:calora/domain/model/notification/reminder_request.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

abstract class NotificationRepo {
  Future<List<NotificationSetting>> getNotificationSettings();
  Future<void> postNotificationSettings(ReminderRequest request);
  Future<void> deleteNotificationSetting(int id);
  Future<List<ReminderRequest>> getReminders();
  PagingController<int, model.Notification> getNotifications();
  Stream<int> getUnread();
  Future<void> markAsRead(int notificationId);
}
