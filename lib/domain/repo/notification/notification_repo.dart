import 'package:calora/domain/model/notification/notificaiton_setting.dart';
import 'package:calora/domain/model/notification/notification.dart' as model;
import 'package:calora/domain/model/notification/reminder_request.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:calora/domain/model/reminder/reminder_request.dart';

abstract class NotificationRepo {
  Future<List<ReminderRequest>> getReminders();
  Future<ReminderRequest> updateReminder(ReminderRequest request);
  Future<void> deleteReminder(int id);
  PagingController<int, model.Notification> getNotifications();
  Stream<int> getUnread();
  Future<void> markAsRead(int notificationId);
}
