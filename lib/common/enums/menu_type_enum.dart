import 'package:calora/common/gen/strings.dart';

enum MenuTypeEnum {
  breakfast,
  lunch,
  dinner,
  snack
  ;

  bool get isBreakfast => this == MenuTypeEnum.breakfast;
  bool get isLunch => this == MenuTypeEnum.lunch;
  bool get isDinner => this == MenuTypeEnum.dinner;
  bool get isSnack => this == MenuTypeEnum.snack;

  String get toApi {
    switch (this) {
      case MenuTypeEnum.breakfast:
        return 'Breakfast';
      case MenuTypeEnum.lunch:
        return 'Lunch';
      case MenuTypeEnum.dinner:
        return 'Dinner';
      case MenuTypeEnum.snack:
        return 'Snack';
    }
  }

  static MenuTypeEnum fromApi(String? value) {
    switch (value) {
      case 'Breakfast':
        return MenuTypeEnum.breakfast;
      case 'Lunch':
        return MenuTypeEnum.lunch;
      case 'Dinner':
        return MenuTypeEnum.dinner;
      case 'Snack':
        return MenuTypeEnum.snack;
      default:
        return MenuTypeEnum.breakfast;
    }
  }

  String get displayName {
    switch (this) {
      case MenuTypeEnum.breakfast:
        return Strings.breakfast;
      case MenuTypeEnum.lunch:
        return Strings.lunch;
      case MenuTypeEnum.dinner:
        return Strings.dinner;
      case MenuTypeEnum.snack:
        return Strings.snack;
    }
  }

  static MenuTypeEnum fromDisplayName(String value) {
    for (final type in MenuTypeEnum.values) {
      if (type.displayName == value) return type;
    }
    return MenuTypeEnum.breakfast;
  }
}
