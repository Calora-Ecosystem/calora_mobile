import 'package:calora/domain/model/calories/calories_data.dart';
import 'package:calora/domain/repo/calories/calories_repo.dart';
import 'package:injectable/injectable.dart' show injectable;
import 'package:management/management.dart';

import 'meals_management.dart';

@injectable
class MealsManager extends Manager<MealsState, MealsEffect> {
  final CaloriesRepo caloriesRepo;

  MealsManager(this.caloriesRepo) : super(const MealsState());

  void getMeal(MealType type) {
    caloriesRepo.getMeals().handle(
      onStart: () {},
      onData: (mealList) {
        final selectedMeal = mealList.firstWhere((meal) => meal.type == type);
        emit(MealsState(meal: selectedMeal));
      },
      onError: (error) => emit(const MealsState()),
    );
  }

  void openAddMealPage() {
    publish(MealsEffect.openAddMealPage());
  }
}
