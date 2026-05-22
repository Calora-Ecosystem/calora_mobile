import 'package:calora/domain/model/meal/food/food_models.dart';
import 'package:calora/domain/model/meal/meal_type_data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'add_meals_management.freezed.dart';

/// Which paginated list the food grid is currently rendering.
enum FoodTab {
  /// Category cards — "All Dishes". Not a food list; tapping a card
  /// pushes [DishesPage].
  categories,

  /// `/food?Latest=true` — recently eaten foods.
  latest,

  /// `/food?IsUserFood=true` — foods the user authored.
  userFoods,

  /// `/food?IsFavourite=true` — favourited foods.
  favourites,

  /// Search overlay — `FilteringExpression=name$$<q>`. Active while the
  /// search field has 3+ characters.
  search,
}

@freezed
abstract class AddMealsState with _$AddMealsState {
  const factory AddMealsState({
    @Default(false) bool hasOpenedCreator,
    @Default(FoodTab.categories) FoodTab activeTab,
    @Default([]) List<MealTypeData> mealCategories,
    @Default([]) List<ScannerFood> scannedFoods,
    @Default([]) List<ScannerFood> scannedFoodsByVoice,
    int? addedFoodId,
    @Default(false) bool isLoading,
    @Default(false) bool isMealCategory,
    @Default('') String searchQuery,
  }) = _AddMealsState;
}

@freezed
class AddMealsEffect with _$AddMealsEffect {
  const factory AddMealsEffect.openDishesPage(MealTypeData meal) =
      OpenDishesPage;

  const factory AddMealsEffect.openCreatorWithImage() = OpenCreatorWithImage;

  const factory AddMealsEffect.openCreatorWithSpeech() = OpenCreatorWithSpeech;

  const factory AddMealsEffect.openAboutPage(FoodModel food, bool isFavourite) =
      OpenAboutPage;

  const factory AddMealsEffect.showSuccessDialog(String message) =
      ShowSuccessDialog;

  const factory AddMealsEffect.showErrorDialog(String message) =
      ShowErrorDialog;
}
