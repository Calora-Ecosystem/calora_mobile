import 'package:calora/common/gen/strings.dart';
import 'package:calora/data/api/profile_api.dart';
import 'package:calora/domain/model/notification/notificaiton_setting.dart';
import 'package:calora/domain/model/notification/notification_setting_type.dart';
import 'package:calora/domain/model/notification/reminder_request.dart';
import 'package:calora/domain/repo/notification/notification_repo.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: NotificationRepo)
class NotificationRepoImpl extends NotificationRepo {
  final ProfileApi profileApi;

  NotificationRepoImpl(this.profileApi);

  @override
  Future<List<NotificationSetting>> getNotificationSettings() {
    return Future.value(notifications);
  }

  List<NotificationSetting> notifications = [
    NotificationSetting(
      id: '1',
      title: Strings.mealReminders,
      type: NotificationSettingType.mealReminder,
      value: [Strings.before20Min, Strings.before20Min, Strings.before10Min],
    ),
    NotificationSetting(
      id: '2',
      title: Strings.remindersToDrinkWater,
      type: NotificationSettingType.waterReminder,
      value: [Strings.every3Hour],
    ),
    NotificationSetting(
      id: '3',
      title: Strings.sleepReminders,
      type: NotificationSettingType.sleepReminder,
      value: ['22:00'],
    ),
    NotificationSetting(
      id: '4',
      title: Strings.notesForThe30DayChallenge,
      type: NotificationSettingType.thirtyDayChallenges,
      value: ['22:00'],
    ),
  ];

  @override
  Future<void> deleteNotificationSetting(int id) async {
    await profileApi.deleteReminder(id);
  }

  @override
  Future<void> postNotificationSettings(ReminderRequest reminder) async {
    await profileApi.postReminders(reminder: reminder);
  }

  @override
  Future<List<ReminderRequest>> getReminders() async {
    final response = await profileApi.getReminders();
    final List<dynamic> content = response.data['content'] ?? [];
    return content.map((e) => ReminderRequest.fromJson(e as Map<String, dynamic>)).toList();
  }
}
