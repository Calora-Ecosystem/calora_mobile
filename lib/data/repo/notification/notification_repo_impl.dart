import 'package:calora/domain/model/notification/notificaiton_setting.dart';
import 'package:calora/domain/model/notification/notification_setting_type.dart';
import 'package:calora/domain/repo/notification/notification_repo.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: NotificationRepo)
class NotificationRepoImpl extends NotificationRepo {
  @override
  Future<List<NotificationSetting>> getNotificationSettings() {
    return Future.value(notifications);
  }

  List<NotificationSetting> notifications = [
    NotificationSetting(
      id: "1",
      title: "Ovqatlanish uchun eslatmalar",
      type: NotificationSettingType.mealReminder,
    ),
    NotificationSetting(
      id: "2",
      title: "Suv ichish uchun eslatmalar",
      type: NotificationSettingType.waterReminder,
    ),
    NotificationSetting(
      id: "3",
      title: "Uxlash uchun eslatmalar",
      type: NotificationSettingType.sleepReminder,
    ),
    NotificationSetting(
      id: "4",
      title: "30 kunlik chellenj eslatmalar",
      type: NotificationSettingType.sleepReminder,
    ),
  ];
}
