import 'package:calora/domain/model/meal/food/food_models.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'dishes_management.freezed.dart';

@freezed
abstract class DishesState with _$DishesState {
  const factory DishesState({
    @Default(false) bool isLoading,
    FoodModel? food,
  }) = _DishesState;
}

@freezed
abstract class DishesEffect with _$DishesEffect {
  const factory DishesEffect.openInfoSheet(FoodModel food, bool isFavourite) =
      _DishesEffect;
}
