import 'package:calora/domain/model/notification/reminder_request.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_setting_sheet_management.freezed.dart';

@freezed
abstract class NotificationSettingSheetState with _$NotificationSettingSheetState {
  const factory NotificationSettingSheetState({
    @Default(false) bool isEnabled,
    DateTime? singleTime,
    @Default({}) Map<String, MealTimeSetting> mealTimes,
    @Default([]) List<ReminderRequest> existingReminders,
  }) = _NotificationSettingSheetState;
}

@freezed
abstract class MealTimeSetting with _$MealTimeSetting {
  const factory MealTimeSetting({required bool enabled, required DateTime time}) = _MealTimeSetting;
}

@freezed
sealed class NotificationSettingSheetEffect with _$NotificationSettingSheetEffect {
  const factory NotificationSettingSheetEffect.save() = SaveNotificationSettings;
}
