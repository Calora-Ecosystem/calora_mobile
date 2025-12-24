import 'package:calora/domain/model/notification/notification_setting_type.dart';

class NotificationSetting {
  final String id;
  final String title;
  final NotificationSettingType type;
  final dynamic value;

  NotificationSetting({
    this.value = '',
    this.title = '',
    this.id = '',
    this.type = NotificationSettingType.none,
  });
}
