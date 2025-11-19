import 'package:calora/domain/model/meal/dish/dish_data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'dishes_management.freezed.dart';

@freezed
abstract class DishesState with _$DishesState {
  const factory DishesState({@Default([]) List<DishData> dishes}) = _DishesState;
}

@freezed
abstract class DishesEffect with _$DishesEffect {
  const factory DishesEffect() = _DishesEffect;
}
