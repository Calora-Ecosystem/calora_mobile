import 'package:calora/domain/model/meal/meal_type_data.dart';
import 'package:calora/domain/repo/calories/calories_repo.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

import 'add_meals_management.dart';

@injectable
class AddMealsManager extends Manager<AddMealsState, AddMealsEffect> {
  final CaloriesRepo _repo;

  AddMealsManager(this._repo) : super(const AddMealsState());

  void fetchFoodCategory() async {
    await _repo.fetchFoodCategory().handle(
      onStart: () => emit(state.copyWith(isLoading: true)),
      onData: (categories) => emit(state.copyWith(mealCategories: categories, isLoading: false)),
      onDone: () => emit(state.copyWith(isLoading: false)),
      onError: (error) => emit(state.copyWith(isLoading: false)),
    );
  }

  void openDishesPage(MealTypeData meal) {
    publish(AddMealsEffect.openDishesPage(meal));
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
