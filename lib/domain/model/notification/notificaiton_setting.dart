import 'package:calora/domain/model/notification/notification_setting_type.dart';

class NotificationSetting{
  final String id;
  final String title;
  final NotificationSettingType type;

  NotificationSetting({
    this.title = "",
    this.id = "",
    this.type = NotificationSettingType.none,
  });
}