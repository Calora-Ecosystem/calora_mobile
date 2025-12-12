import 'package:calora/domain/model/meal/food/food_models.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'dishes_management.freezed.dart';

@freezed
abstract class DishesState with _$DishesState {
  const factory DishesState({
    @Default([]) List<FoodListItem> foods,
    @Default(false) bool isLoading,
    @Default(null) FoodItem? food,
  }) = _DishesState;
}

@freezed
abstract class DishesEffect with _$DishesEffect {
  const factory DishesEffect.openInfoSheet(FoodItem food) = _DishesEffect;
}
