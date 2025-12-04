import 'package:calora/common/gen/strings.dart';
import 'package:calora/domain/model/calories/calories_data.dart';
import 'package:calora/domain/model/meal/meal_type_data.dart';

extension MealTypeText on MealType {
  String get title {
    switch (this) {
      case MealType.breakfast:
        return Strings.breakfast;
      case MealType.lunch:
        return Strings.lunch;
      case MealType.snacks:
        return Strings.snacks;
      case MealType.dinner:
        return Strings.dinner;
    }
  }
}

extension MealCategoryTitle on MealCategory {
  String get displayName {
    switch (this) {
      case MealCategory.breakfast:
        return Strings.breakfast;
      case MealCategory.liquid:
        return Strings.liquidFoods;
      case MealCategory.drinks:
        return Strings.drinks;
      case MealCategory.fastFood:
        return Strings.fastFood;
      case MealCategory.pureed:
        return Strings.deepDishes;
    }
  }
}
