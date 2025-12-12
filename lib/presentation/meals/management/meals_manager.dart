import 'package:calora/domain/model/calories/calories_data.dart';
import 'package:calora/domain/repo/calories/calories_repo.dart';
import 'package:injectable/injectable.dart' show injectable;
import 'package:management/management.dart';

import 'meals_management.dart';

@injectable
class MealsManager extends Manager<MealsState, MealsEffect> {
  final CaloriesRepo caloriesRepo;

  MealsManager(this.caloriesRepo) : super(const MealsState());

  void setMealFromList(MealType type, List<MealData> meals) {
    final meal = meals.firstWhere(
      (m) => m.type == type,
      orElse: () => MealData(type: type, max: 0, value: 0, mass: 0, carbohydrates: 0, proteins: 0, oils: 0),
    );
    emit(state.copyWith(meal: meal));
  }

  void fetchMenuItem(DateTime date) {
    caloriesRepo
        .fetchMenuItem(date)
        .handle(
          onStart: () => emit(state.copyWith(isLoading: true)),
          onData: (value) => emit(state.copyWith(menuItems: value, isLoading: false)),
          onDone: () => emit(state.copyWith(isLoading: false)),
          onError: (error) => emit(state.copyWith(isLoading: false)),
        );
  }

  void openAddMealPage() {
    publish(MealsEffect.openAddMealPage());
  }
}
