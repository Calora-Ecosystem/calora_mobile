import 'package:calora/domain/model/meal/meal_type_data.dart';
import 'package:calora/domain/repo/calories/calories_repo.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

import 'dishes_management.dart';

@injectable
class DishesManager extends Manager<DishesState, DishesEffect> {
  final CaloriesRepo caloriesRepo;

  DishesManager(this.caloriesRepo) : super(const DishesState());

  void getDishes(MealCategory category) {
    caloriesRepo.getDishes(category).then((value) => emit(state.copyWith(dishes: value)));
  }
}
