// notification_setting_sheet_management.dart
import 'package:calora/domain/model/notification/notification_setting_type.dart';
import 'package:calora/domain/model/notification/reminder_request.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_setting_sheet_management.freezed.dart';

@freezed
abstract class NotificationSettingSheetState with _$NotificationSettingSheetState {
  const factory NotificationSettingSheetState({
    @Default(false) bool isEnabled,
    @Default(0) int selectedIndex,
    @Default(null) DateTime? selectedTime,
    @Default(false) bool breakfastEnabled,
    @Default(false) bool lunchEnabled,
    @Default(false) bool dinnerEnabled,
    @Default(0) int breakfastIndex,
    @Default(0) int lunchIndex,
    @Default(0) int dinnerIndex,
    @Default(null) int? expandedMealIndex,
    @Default([]) List<ReminderRequest> existingReminders,
  }) = _NotificationSettingSheetState;
}

@freezed
sealed class NotificationSettingSheetEffect with _$NotificationSettingSheetEffect {
  const factory NotificationSettingSheetEffect.save({
    required NotificationSettingType type,
    dynamic data,
  }) = SaveNotificationSettings;
  const factory NotificationSettingSheetEffect.delete({required int id}) =
      DeleteNotificationSetting;
}
