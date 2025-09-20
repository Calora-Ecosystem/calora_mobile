import 'package:calora/presentation/notification/settings/management/notification_settings_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class NotificationSettingsManager
    extends Manager<NotificationSettingsState, NotificationSettingsEffect> {
  NotificationSettingsManager() : super(NotificationSettingsState());
}
