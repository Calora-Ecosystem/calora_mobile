import 'package:calora/domain/model/notification/notificaiton_setting.dart';
import 'package:calora/domain/model/notification/reminder_request.dart';

abstract class NotificationRepo {
  Future<List<NotificationSetting>> getNotificationSettings();
  Future<void> postNotificationSettings(ReminderRequest request);
  Future<void> deleteNotificationSetting(int id);
  Future<List<ReminderRequest>> getReminders();
}
