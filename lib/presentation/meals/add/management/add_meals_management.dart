import 'package:calora/domain/model/meal/meal_type_data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'add_meals_management.freezed.dart';

@freezed
abstract class AddMealsState with _$AddMealsState {
  const factory AddMealsState() = _AddMealsState;
}

@freezed
abstract class AddMealsEffect with _$AddMealsEffect {
  const factory AddMealsEffect.openDishesPage(MealCategory category) = _OpenDishesPage;
}
