import 'package:calora/common/enums/reminder_types_enum.dart';
import 'package:calora/domain/model/reminder/reminder_request.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_settings_management.freezed.dart';

@freezed
abstract class NotificationSettingsState with _$NotificationSettingsState {
  const factory NotificationSettingsState({
    @Default(false) bool loading,
    @Default(const []) List<ReminderRequest> remoteReminders,
    @Default({}) Map<ReminderTypesEnum, ReminderRequest> reminders,
    @Default({}) Set<ReminderTypesEnum> updatingReminders,
    @Default(false) bool isSaving,
  }) = _NotificationSettingsState;
}

@freezed
sealed class NotificationSettingsEffect with _$NotificationSettingsEffect {
  const factory NotificationSettingsEffect() = _NotificationSettingsEffect;
}
