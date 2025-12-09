import 'package:calora/domain/model/meal/meal_type_data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'add_meals_management.freezed.dart';

@freezed
abstract class AddMealsState with _$AddMealsState {
  const factory AddMealsState({@Default(false) bool hasOpenedCreator}) = _AddMealsState;
}

@freezed
class AddMealsEffect with _$AddMealsEffect {
  const factory AddMealsEffect.openDishesPage(MealCategory category) = OpenDishesPage;

  const factory AddMealsEffect.openCreatorWithImage() = OpenCreatorWithImage;

  const factory AddMealsEffect.openCreatorWithSpeech() = OpenCreatorWithSpeech;
}
