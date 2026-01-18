import 'package:calora/domain/model/calories/calories_data.dart';
import 'package:calora/domain/repo/calories/calories_repo.dart';
import 'package:calora/presentation/meals/management/meals_management.dart';
import 'package:injectable/injectable.dart' show injectable;
import 'package:management/management.dart';

@injectable
class MealsManager extends Manager<MealsState, MealsEffect> {
  final CaloriesRepo caloriesRepo;

  MealsManager(this.caloriesRepo) : super(const MealsState());

  void fetchMenuItem(DateTime date, MealType type) {
    caloriesRepo
        .fetchMenuItem(date, type.name)
        .handle(
          onStart: () => emit(state.copyWith(isLoading: true)),
          onData: (value) {
            emit(state.copyWith(menuItems: value, isLoading: false));
          },
          onDone: () => emit(state.copyWith(isLoading: false)),
          onError: (error) => emit(state.copyWith(isLoading: false)),
        );
  }

  MealData? getMealByType(MealType type, List<MealData> meals) {
    for (final meal in meals) {
      if (meal.type == type) return meal;
    }
    return null;
  }

  void fetchSummary(DateTime date, MealType type) {
    caloriesRepo
        .fetchSummary(date)
        .handle(
          onStart: () => emit(state.copyWith(isSummary: true)),
          onData: (result) {
            final meal = getMealByType(type, result.meals);
            emit(state.copyWith(meal: meal, isSummary: false));
          },
          onDone: () => emit(state.copyWith(isSummary: false)),
          onError: (error) => emit(state.copyWith(isSummary: false)),
        );
  }

  void openAddMealPage() {
    publish(MealsEffect.openAddMealPage());
  }
}
