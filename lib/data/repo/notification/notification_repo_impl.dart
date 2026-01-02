import 'package:calora/data/api/notification_api.dart';
import 'package:calora/domain/model/reminder/reminder_request.dart';
import 'package:calora/domain/repo/notification/notification_repo.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: NotificationRepo)
class NotificationRepoImpl extends NotificationRepo {
  final NotificationApi _api;
  NotificationRepoImpl(this._api);

  @override
  Future<List<ReminderRequest>> getReminders() async {
    return await _api.getReminders();
  }

  @override
  Future<ReminderRequest> updateReminder(ReminderRequest request) async {
    return await _api.updateReminder(request);
  }

  @override
  Future<void> deleteReminder(int id) async {
    await _api.deleteReminder(id);
  }
}
