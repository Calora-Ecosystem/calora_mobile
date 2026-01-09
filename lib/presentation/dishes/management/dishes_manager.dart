import 'package:calora/domain/model/meal/menu/menu_info.dart';
import 'package:calora/domain/repo/calories/calories_repo.dart';
import 'package:calora/presentation/dishes/management/dishes_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class DishesManager extends Manager<DishesState, DishesEffect> {
  final CaloriesRepo caloriesRepo;

  DishesManager(this.caloriesRepo) : super(const DishesState());

  void getDishes(int categoryId) {
    caloriesRepo
        .fetchFoods(false)
        .handle(
          onStart: () => emit(state.copyWith(isLoading: true)),
          onData: (value) {
            final filteredFoods = value
                .where((food) => food.categoryId == categoryId)
                .toList();
            emit(state.copyWith(foods: filteredFoods, isLoading: false));
          },
          onDone: () => emit(state.copyWith(isLoading: false)),
          onError: (error) => emit(state.copyWith(isLoading: false)),
        );
  }

  void getFoodById(int id, bool isFavourite) {
    caloriesRepo
        .fetchFoodById(id)
        .handle(
          onStart: () => emit(state.copyWith(isLoading: true)),
          onData: (value) {
            emit(state.copyWith(food: value, isLoading: false));
            publish(DishesEffect.openInfoSheet(value, isFavourite));
          },
          onDone: () => emit(state.copyWith(isLoading: false)),
          onError: (error) => emit(state.copyWith(isLoading: false)),
        );
  }

  Future<bool> saveMenuItem(MenuInfo item) async {
    bool success = false;
    await caloriesRepo
        .saveMenuItem(item)
        .handle(
          onStart: () => emit(state.copyWith(isLoading: true)),
          onData: (_) => success = true,
          onDone: () => emit(state.copyWith(isLoading: false)),
          onError: (error) {
            success = false;
            emit(state.copyWith(isLoading: false));
          },
        );
    return success;
  }

  void addFavourite(int id) {
    caloriesRepo
        .addFavourite(id)
        .handle(
          onStart: () => emit(state.copyWith(isLoading: true)),
          onDone: () => emit(state.copyWith(isLoading: false)),
          onError: (error) => emit(state.copyWith(isLoading: false)),
        );
  }
}
