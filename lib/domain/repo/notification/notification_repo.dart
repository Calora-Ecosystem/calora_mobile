import 'package:calora/domain/model/notification/notificaiton_setting.dart';

abstract class NotificationRepo {
  Future<List<NotificationSetting>> getNotificationSettings();
}
