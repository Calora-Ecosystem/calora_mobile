import 'package:calora/domain/model/meal/food/food_models.dart';
import 'package:calora/domain/model/meal/meal_type_data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'add_meals_management.freezed.dart';

@freezed
abstract class AddMealsState with _$AddMealsState {
  const factory AddMealsState({
    @Default(false) bool hasOpenedCreator,
    @Default(0) int selectedToggleIndex,
    @Default([]) List<MealTypeData> mealCategories,
    @Default([]) List<FoodModel> favouriteFoods,
    @Default([]) List<FoodModel> latestFoods,
    @Default([]) List<ScannerFood> scannedFoods,
    @Default([]) List<ScannerFood> scannedFoodsByVoice,
    @Default([]) List<FoodModel> userFoods,
    int? addedFoodId,
    @Default(false) bool isLoading,
    @Default([]) List<FoodModel> searchFoods,
    @Default(false) bool isSearch,
    @Default(false) bool isSearchMode,
    @Default(false) bool isMealCategory,
    @Default(false) bool isLatest,
    @Default(false) bool isUserFoods,
    @Default(false) bool isFavourite,
  }) = _AddMealsState;
}

@freezed
class AddMealsEffect with _$AddMealsEffect {
  const factory AddMealsEffect.openDishesPage(MealTypeData meal) = OpenDishesPage;

  const factory AddMealsEffect.openCreatorWithImage() = OpenCreatorWithImage;

  const factory AddMealsEffect.openCreatorWithSpeech() = OpenCreatorWithSpeech;

  const factory AddMealsEffect.openAboutPage(FoodModel food, bool isFavourite) = OpenAboutPage;

  const factory AddMealsEffect.showSuccessDialog(String message) = ShowSuccessDialog;

  const factory AddMealsEffect.showErrorDialog(String message) = ShowErrorDialog;
}
