import 'package:calora/domain/model/reminder/notification.dart' as model;
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:calora/domain/model/reminder/reminder_request.dart';

abstract class NotificationRepo {
  Future<List<ReminderRequest>> getReminders();
  Future<ReminderRequest> updateReminder(ReminderRequest request);
  Future<void> deleteReminder(int id);
  PagingController<int, model.Notification> getNotifications();
  Stream<int> getUnread();
  Future<List<model.Notification>> fetchNotifications({required int skip, required int take});
  Future<void> markAsRead(int notificationId);
  Future<void> readAll();
}
