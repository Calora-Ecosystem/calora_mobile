import 'package:calora/domain/model/notification/notification_setting_type.dart';
import 'package:calora/domain/model/notification/reminder_request.dart';
import 'package:calora/domain/repo/notification/notification_repo.dart';
import 'package:calora/presentation/input/date/management/notification_setting_sheet_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class NotificationSettingSheetManager extends Manager<NotificationSettingSheetState, NotificationSettingSheetEffect> {
  final NotificationRepo _repo;

  NotificationSettingSheetManager(this._repo) : super(const NotificationSettingSheetState());

  void init(NotificationSettingType type, List<ReminderRequest> reminders) {
    Map<String, MealTimeSetting> mealMap = {};
    bool enabled = false;
    DateTime? single;

    for (final r in reminders) {
      final time = _parseTime(r.time);

      if (type == NotificationSettingType.waterReminder && r.type == "Water") {
        enabled = true;
        single = time;
      } else if (type == NotificationSettingType.mealReminder && r.type == "Food" && r.menu != null) {
        mealMap[r.menu!] = MealTimeSetting(enabled: true, time: time);
        enabled = true;
      } else if (type == NotificationSettingType.sleepReminder && r.type == "Sleep") {
        enabled = true;
        single = time;
      } else if (type == NotificationSettingType.thirtyDayChallenges && r.type == "DailyChallenge") {
        enabled = true;
        single = time;
      }
    }

    emit(
      state.copyWith(
        isEnabled: enabled,
        singleTime: single ?? DateTime.now(),
        mealTimes: mealMap,
        existingReminders: reminders,
      ),
    );
  }

  void toggleMain(bool v) => emit(state.copyWith(isEnabled: v));

  void setSingleTime(DateTime t) => emit(state.copyWith(singleTime: t));

  void toggleMeal(String menu, bool v) {
    final map = Map<String, MealTimeSetting>.from(state.mealTimes);
    if (v) {
      map[menu] = MealTimeSetting(enabled: true, time: map[menu]?.time ?? DateTime.now());
    } else {
      map.remove(menu);
    }
    emit(state.copyWith(mealTimes: map));
  }

  void setMealTime(String menu, DateTime t) {
    final current = state.mealTimes[menu];
    if (current == null) return;
    final map = Map<String, MealTimeSetting>.from(state.mealTimes);
    map[menu] = current.copyWith(time: t);
    emit(state.copyWith(mealTimes: map));
  }

  Future<void> save(NotificationSettingType type) async {
    for (final r in state.existingReminders) {
      if (r.id != null) await _repo.deleteNotificationSetting(r.id!);
    }

    if (type == NotificationSettingType.waterReminder && state.isEnabled) {
      await _repo.postNotificationSettings(
        ReminderRequest(time: _format(state.singleTime!), type: "Water", menu: "Breakfast"),
      );
    } else if (type == NotificationSettingType.mealReminder) {
      for (final e in state.mealTimes.entries) {
        await _repo.postNotificationSettings(ReminderRequest(time: _format(e.value.time), type: "Food", menu: e.key));
      }
    } else if (type == NotificationSettingType.sleepReminder && state.isEnabled) {
      await _repo.postNotificationSettings(
        ReminderRequest(time: _format(state.singleTime!), type: "Sleep", menu: "Breakfast"),
      );
    } else if (type == NotificationSettingType.thirtyDayChallenges && state.isEnabled) {
      await _repo.postNotificationSettings(
        ReminderRequest(time: _format(state.singleTime!), type: "DailyChallenge", menu: "Breakfast"),
      );
    }

    publish(const NotificationSettingSheetEffect.save());
  }

  DateTime _parseTime(String t) {
    final p = t.split(':');
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day, int.parse(p[0]), int.parse(p[1]));
  }

  String _format(DateTime d) => "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:00";
}
