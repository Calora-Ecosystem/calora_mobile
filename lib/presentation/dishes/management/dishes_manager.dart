import 'package:calora/domain/repo/calories/calories_repo.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

import 'dishes_management.dart';

@injectable
class DishesManager extends Manager<DishesState, DishesEffect> {
  final CaloriesRepo caloriesRepo;

  DishesManager(this.caloriesRepo) : super(const DishesState());

  void getDishes(int categoryId) {
    caloriesRepo.fetchFoods().handle(
      onStart: () => emit(state.copyWith(isLoading: true)),
      onData: (value) {
        final filteredFoods = value.where((food) => food.categoryId == categoryId).toList();
        emit(state.copyWith(foods: filteredFoods, isLoading: false));
      },
      onDone: () => emit(state.copyWith(isLoading: false)),
      onError: (error) => emit(state.copyWith(isLoading: false)),
    );
  }

  void getFoodById(int id) {
    caloriesRepo
        .fetchFoodById(id)
        .handle(
          onStart: () => emit(state.copyWith(isLoading: true)),
          onData: (value) {
            emit(state.copyWith(food: value, isLoading: false));
            publish(DishesEffect.openInfoSheet(value));
          },
          onDone: () => emit(state.copyWith(isLoading: false)),
          onError: (error) => emit(state.copyWith(isLoading: false)),
        );
  }
}
