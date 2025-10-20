import 'package:calora/domain/model/notification/notification_setting_type.dart';
import 'package:calora/domain/model/notification/reminder_request.dart';
import 'package:calora/domain/repo/notification/notification_repo.dart';
import 'package:calora/presentation/input/date/management/notification_setting_sheet_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class NotificationSettingSheetManager
    extends Manager<NotificationSettingSheetState, NotificationSettingSheetEffect> {
  final NotificationRepo _notificationRepo;

  NotificationSettingSheetManager(this._notificationRepo) : super(NotificationSettingSheetState());

  void init(NotificationSettingType type, List<ReminderRequest> reminders) {
    final newState = _initializeState(type, reminders);
    emit(newState);
  }

  NotificationSettingSheetState _initializeState(
    NotificationSettingType type,
    List<ReminderRequest> reminders,
  ) {
    bool isEnabled = false;
    int selectedIndex = 0;
    DateTime? selectedTime;
    bool breakfastEnabled = false, lunchEnabled = false, dinnerEnabled = false;
    int breakfastIndex = 0, lunchIndex = 0, dinnerIndex = 0;

    for (final reminder in reminders) {
      final time = _mapServerTimeToIndex(reminder.time, type);
      if (type == NotificationSettingType.waterReminder && reminder.type == "Water") {
        isEnabled = true;
        selectedIndex = time;
      } else if (type == NotificationSettingType.mealReminder) {
        if (reminder.menu == "Breakfast" && reminder.type == "Food") {
          breakfastEnabled = true;
          breakfastIndex = time;
        } else if (reminder.menu == "Lunch" && reminder.type == "Food") {
          lunchEnabled = true;
          lunchIndex = time;
        } else if (reminder.menu == "Dinner" && reminder.type == "Food") {
          dinnerEnabled = true;
          dinnerIndex = time;
        }
      } else if (type == NotificationSettingType.sleepReminder && reminder.type == "Sleep") {
        isEnabled = true;
        selectedTime = DateTime.parse("2023-01-01 ${reminder.time}");
      } else if (type == NotificationSettingType.thirtyDayChallenges &&
          reminder.type == "DailyChallenge") {
        isEnabled = true;
        selectedTime = DateTime.parse("2023-01-01 ${reminder.time}");
      }
    }

    return NotificationSettingSheetState(
      isEnabled: isEnabled,
      selectedIndex: selectedIndex,
      selectedTime: selectedTime ?? DateTime.now(),
      breakfastEnabled: breakfastEnabled,
      lunchEnabled: lunchEnabled,
      dinnerEnabled: dinnerEnabled,
      breakfastIndex: breakfastIndex,
      lunchIndex: lunchIndex,
      dinnerIndex: dinnerIndex,
      existingReminders: reminders,
    );
  }

  void toggleEnabled(bool value) {
    emit(state.copyWith(isEnabled: value));
  }

  void setSelectedIndex(int index) {
    emit(state.copyWith(selectedIndex: index));
  }

  void setSelectedTime(DateTime time) {
    emit(state.copyWith(selectedTime: time));
  }

  void toggleBreakfastEnabled(bool value) {
    emit(state.copyWith(breakfastEnabled: value));
  }

  void toggleLunchEnabled(bool value) {
    emit(state.copyWith(lunchEnabled: value));
  }

  void toggleDinnerEnabled(bool value) {
    emit(state.copyWith(dinnerEnabled: value));
  }

  void setBreakfastIndex(int index) {
    emit(state.copyWith(breakfastIndex: index));
  }

  void setLunchIndex(int index) {
    emit(state.copyWith(lunchIndex: index));
  }

  void setDinnerIndex(int index) {
    emit(state.copyWith(dinnerIndex: index));
  }

  void toggleExpandedMealIndex(int index) {
    emit(state.copyWith(expandedMealIndex: state.expandedMealIndex == index ? null : index));
  }

  void saveSettings(NotificationSettingType type) async {
    if (type == NotificationSettingType.waterReminder) {
      final existing = state.existingReminders.firstWhere(
        (r) => r.type == "Water",
        orElse: () => ReminderRequest(time: "", type: "", menu: ""),
      );
      if (state.isEnabled) {
        final time = _mapIndexToServerTime(state.selectedIndex, type);
        if (existing.id != null) {
          await _notificationRepo.deleteNotificationSetting(existing.id!);
        }
        await _notificationRepo.postNotificationSettings(
          ReminderRequest(time: time, type: "Water", menu: "Breakfast"),
        );
      } else if (existing.id != null) {
        publish(DeleteNotificationSetting(id: existing.id!));
        await _notificationRepo.deleteNotificationSetting(existing.id!);
      }
    } else if (type == NotificationSettingType.mealReminder) {
      final meals = [
        MealReminderState(
          menu: "Breakfast",
          enabled: state.breakfastEnabled,
          index: state.breakfastIndex,
        ),
        MealReminderState(menu: "Lunch", enabled: state.lunchEnabled, index: state.lunchIndex),
        MealReminderState(menu: "Dinner", enabled: state.dinnerEnabled, index: state.dinnerIndex),
      ];

      for (final meal in meals) {
        final existing = state.existingReminders.firstWhere(
          (r) => r.type == "Food" && r.menu == meal.menu,
          orElse: () => ReminderRequest(time: "", type: "", menu: ""),
        );

        if (meal.enabled) {
          final time = _mapIndexToServerTime(meal.index, type);
          if (existing.id != null) {
            await _notificationRepo.deleteNotificationSetting(existing.id!);
          }
          await _notificationRepo.postNotificationSettings(
            ReminderRequest(time: time, type: "Food", menu: meal.menu),
          );
        } else if (existing.id != null) {
          publish(DeleteNotificationSetting(id: existing.id!));
          await _notificationRepo.deleteNotificationSetting(existing.id!);
        }
      }
    } else if (type == NotificationSettingType.sleepReminder ||
        type == NotificationSettingType.thirtyDayChallenges) {
      final existing = state.existingReminders.firstWhere(
        (r) =>
            r.type == (type == NotificationSettingType.sleepReminder ? "Sleep" : "DailyChallenge"),
        orElse: () => ReminderRequest(time: "", type: "", menu: ""),
      );
      if (state.isEnabled && state.selectedTime != null) {
        final time = _formatTimeOfDay(state.selectedTime!);
        if (existing.id != null) {
          await _notificationRepo.deleteNotificationSetting(existing.id!);
        }
        await _notificationRepo.postNotificationSettings(
          ReminderRequest(
            time: time,
            type: type == NotificationSettingType.sleepReminder ? "Sleep" : "DailyChallenge",
            menu: "Breakfast",
          ),
        );
      } else if (existing.id != null) {
        publish(DeleteNotificationSetting(id: existing.id!));
        await _notificationRepo.deleteNotificationSetting(existing.id!);
      }
    }
    publish(SaveNotificationSettings(type: type, data: null));
  }

  int _mapServerTimeToIndex(String time, NotificationSettingType type) {
    if (type == NotificationSettingType.waterReminder) {
      switch (time) {
        case "01:00:00":
          return 0;
        case "02:00:00":
          return 1;
        case "03:00:00":
          return 2;
        case "04:00:00":
          return 3;
        case "05:00:00":
          return 4;
        default:
          return 0;
      }
    } else if (type == NotificationSettingType.mealReminder) {
      switch (time) {
        case "00:10:00":
          return 0;
        case "00:20:00":
          return 1;
        case "00:30:00":
          return 2;
        case "00:40:00":
          return 3;
        case "00:50:00":
          return 4;
        default:
          return 0;
      }
    }
    return 0;
  }

  String _mapIndexToServerTime(int index, NotificationSettingType type) {
    if (type == NotificationSettingType.waterReminder) {
      const times = ["01:00:00", "02:00:00", "03:00:00", "04:00:00", "05:00:00"];
      return times[index];
    } else if (type == NotificationSettingType.mealReminder) {
      const times = ["00:10:00", "00:20:00", "00:30:00", "00:40:00", "00:50:00"];
      return times[index];
    }
    return "00:00:00";
  }

  String _formatTimeOfDay(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute:00";
  }
}

class MealReminderState {
  final String menu;
  final bool enabled;
  final int index;

  MealReminderState({required this.menu, required this.enabled, required this.index});
}
