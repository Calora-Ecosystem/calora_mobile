import 'package:calora/domain/model/notification/notificaiton_setting.dart';

abstract class NotificationRepo {
  Future<List<NotificationSetting>> getNotificationSettings();
  Future<void> postNotificationSettings(String menu, String time, String type);
  Future<void> deleteNotificationSetting(int id);
}
