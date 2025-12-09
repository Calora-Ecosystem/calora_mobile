import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/domain/model/meal/meal_type_data.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

import 'add_meals_management.dart';

@injectable
class AddMealsManager extends Manager<AddMealsState, AddMealsEffect> {
  AddMealsManager() : super(const AddMealsState());

  final mealTypes = [
    MealTypeData(name: Strings.liquidFoods, image: Assets.images.liquidFoods.image(), type: MealCategory.liquid),
    MealTypeData(name: Strings.deepDishes, image: Assets.images.solidFoods.image(), type: MealCategory.pureed),
    MealTypeData(name: Strings.drinks, image: Assets.images.drinks.image(), type: MealCategory.drinks),
    MealTypeData(name: Strings.breakfast, image: Assets.images.morningMeal.image(), type: MealCategory.breakfast),
    MealTypeData(name: Strings.fastFood, image: Assets.images.fastFoods.image(), type: MealCategory.fastFood),
  ];

  void openDishesPage(MealCategory category) {
    publish(AddMealsEffect.openDishesPage(category));
  }

  void checkInitialRoute(bool shouldOpenCreator) {
    if (shouldOpenCreator && !state.hasOpenedCreator) {
      emit(state.copyWith(hasOpenedCreator: true));
      publish(const AddMealsEffect.openCreatorWithImage());
    }
  }

  void openCreatorAfterProgress() {
    emit(state.copyWith(hasOpenedCreator: false));
    publish(const AddMealsEffect.openCreatorWithImage());
  }

  void markCreatorAsOpened() {
    emit(state.copyWith(hasOpenedCreator: true));
  }

  void resetCreatorFlag() {
    emit(state.copyWith(hasOpenedCreator: false));
  }

  void openCreatorAfterSpeech() {
    publish(const AddMealsEffect.openCreatorWithSpeech());
  }
}
