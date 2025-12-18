import 'package:calora/domain/model/meal/meal_type_data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'add_meals_management.freezed.dart';

@freezed
abstract class AddMealsState with _$AddMealsState {
  const factory AddMealsState({
    @Default(false) bool hasOpenedCreator,
    @Default([]) List<MealTypeData> mealCategories,
    @Default(false) bool isLoading,
  }) = _AddMealsState;
}

@freezed
class AddMealsEffect with _$AddMealsEffect {
  const factory AddMealsEffect.openDishesPage(MealTypeData meal) = OpenDishesPage;

  const factory AddMealsEffect.openCreatorWithImage() = OpenCreatorWithImage;

  const factory AddMealsEffect.openCreatorWithSpeech() = OpenCreatorWithSpeech;
}
