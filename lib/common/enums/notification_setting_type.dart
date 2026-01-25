import 'package:calora/common/gen/strings.dart';

enum ReminderSettingTypeEnum {
  food,
  water,
  sleep,
  dailyChallenge,
  none;

  bool get isNotification => this != ReminderSettingTypeEnum.none;
  bool get isNone => this == ReminderSettingTypeEnum.none;
  bool get isDailyChallenge => this == ReminderSettingTypeEnum.dailyChallenge;
  bool get isFood => this == ReminderSettingTypeEnum.food;
  bool get isWater => this == ReminderSettingTypeEnum.water;
  bool get isSleep => this == ReminderSettingTypeEnum.sleep;

  String get toApi {
    switch (this) {
      case ReminderSettingTypeEnum.food:
        return 'Food';
      case ReminderSettingTypeEnum.water:
        return 'Water';
      case ReminderSettingTypeEnum.sleep:
        return 'Sleep';
      case ReminderSettingTypeEnum.dailyChallenge:
        return 'DailyChallenge';
      case ReminderSettingTypeEnum.none:
        return 'None';
    }
  }

  static ReminderSettingTypeEnum fromApi(String? value) {
    switch (value) {
      case 'Food':
        return ReminderSettingTypeEnum.food;
      case 'Water':
        return ReminderSettingTypeEnum.water;
      case 'Sleep':
        return ReminderSettingTypeEnum.sleep;
      case 'DailyChallenge':
        return ReminderSettingTypeEnum.dailyChallenge;
      default:
        return ReminderSettingTypeEnum.none;
    }
  }

  String get displayName {
    switch (this) {
      case ReminderSettingTypeEnum.food:
        return Strings.mealReminders;
      case ReminderSettingTypeEnum.water:
        return Strings.remindersToDrinkWater;
      case ReminderSettingTypeEnum.sleep:
        return Strings.sleepReminders;
      case ReminderSettingTypeEnum.dailyChallenge:
        return Strings.notesForThe30DayChallenge;
      case ReminderSettingTypeEnum.none:
        return 'None';
    }
  }

  static ReminderSettingTypeEnum fromDisplayName(String value) {
    for (final type in ReminderSettingTypeEnum.values) {
      if (type.displayName == value) return type;
    }
    return ReminderSettingTypeEnum.none;
  }
}
