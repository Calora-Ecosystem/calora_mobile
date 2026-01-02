import 'package:calora/domain/model/reminder/reminder_request.dart';

abstract class NotificationRepo {
  Future<List<ReminderRequest>> getReminders();
  Future<ReminderRequest> updateReminder(ReminderRequest request);
  Future<void> deleteReminder(int id);
}
