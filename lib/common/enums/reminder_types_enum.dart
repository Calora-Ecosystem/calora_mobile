import 'package:calora/common/enums/menu_type_enum.dart';
import 'package:calora/common/enums/notification_setting_type.dart';

enum ReminderTypesEnum {
  breakfast,
  lunch,
  dinner,
  snack,
  water,
  sleep,
  dailyChallenge,
  none
  ;

  bool get isBreakfast => this == ReminderTypesEnum.breakfast;
  bool get isLunch => this == ReminderTypesEnum.lunch;
  bool get isDinner => this == ReminderTypesEnum.dinner;
  bool get isSnack => this == ReminderTypesEnum.snack;
  bool get isWater => this == ReminderTypesEnum.water;
  bool get isSleep => this == ReminderTypesEnum.sleep;
  bool get isDailyChallenge => this == ReminderTypesEnum.dailyChallenge;
  bool get isNone => this == ReminderTypesEnum.none;

  static ReminderTypesEnum fromReminderSettings({required MenuTypeEnum menu, required ReminderSettingTypeEnum type}) {
    switch (type) {
      case ReminderSettingTypeEnum.food:
        switch (menu) {
          case MenuTypeEnum.breakfast:
            return ReminderTypesEnum.breakfast;
          case MenuTypeEnum.lunch:
            return ReminderTypesEnum.lunch;
          case MenuTypeEnum.dinner:
            return ReminderTypesEnum.dinner;
          case MenuTypeEnum.snack:
            return ReminderTypesEnum.snack;
        }
      case ReminderSettingTypeEnum.water:
        return ReminderTypesEnum.water;
      case ReminderSettingTypeEnum.sleep:
        return ReminderTypesEnum.sleep;
      case ReminderSettingTypeEnum.dailyChallenge:
        return ReminderTypesEnum.dailyChallenge;
      case ReminderSettingTypeEnum.none:
        return ReminderTypesEnum.none;
    }
  }
}
