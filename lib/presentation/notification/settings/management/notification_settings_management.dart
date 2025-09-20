
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_settings_management.freezed.dart';

@freezed
abstract class NotificationSettingsState with _$NotificationSettingsState {
  const factory NotificationSettingsState() = _NotificationSettingsState;
}

@freezed
sealed class NotificationSettingsEffect with _$NotificationSettingsEffect {
  const factory NotificationSettingsEffect() = _NotificationSettingsEffect;
}
