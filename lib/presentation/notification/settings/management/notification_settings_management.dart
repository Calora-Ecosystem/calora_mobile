import 'package:calora/domain/model/notification/notificaiton_setting.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_settings_management.freezed.dart';

@freezed
abstract class NotificationSettingsState with _$NotificationSettingsState {
  const factory NotificationSettingsState({
    @Default(false) bool loading,
    @Default([])   List<NotificationSetting> notificationSettings,
  }) = _NotificationSettingsState;
}

@freezed
sealed class NotificationSettingsEffect with _$NotificationSettingsEffect {
  const factory NotificationSettingsEffect() = _NotificationSettingsEffect;
}
