import 'package:calora/common/gen/strings.dart';
import 'package:calora/data/api/profile_api.dart';
import 'package:calora/domain/model/notification/notificaiton_setting.dart';
import 'package:calora/domain/model/notification/notification_setting_type.dart';
import 'package:calora/domain/repo/notification/notification_repo.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: NotificationRepo)
class NotificationRepoImpl extends NotificationRepo {
  final ProfileApi profileApi;

  @override
  Future<List<NotificationSetting>> getNotificationSettings() {
    return Future.value(notifications);
  }

  List<NotificationSetting> notifications = [
    NotificationSetting(
      id: "1",
      title: "Ovqatlanish uchun eslatmalar",
      type: NotificationSettingType.mealReminder,
      value: [Strings.before20Min, Strings.before20Min, Strings.before10Min],
    ),
    NotificationSetting(
      id: "2",
      title: "Suv ichish uchun eslatmalar",
      type: NotificationSettingType.waterReminder,
      value: [Strings.every3Hour],
    ),
    NotificationSetting(
      id: "3",
      title: "Uxlash uchun eslatmalar",
      type: NotificationSettingType.sleepReminder,
      value: ['22:00'],
    ),
    NotificationSetting(
      id: "4",
      title: "30 kunlik chellenj eslatmalar",
      type: NotificationSettingType.sleepReminder,
      value: ['22:00'],
    ),
  ];

  NotificationRepoImpl(this.profileApi);

  @override
  Future<void> deleteNotificationSetting(int id) async {
    await profileApi.deleteReminder(id);
  }

  @override
  Future<void> postNotificationSettings(String menu, String time, String type) async {
    await profileApi.postReminders(menu: menu, time: time, type: type);
  }
}
