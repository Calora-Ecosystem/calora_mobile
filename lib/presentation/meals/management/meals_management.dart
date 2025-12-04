import 'package:calora/domain/model/calories/calories_data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'meals_management.freezed.dart';

@freezed
abstract class MealsState with _$MealsState {
  const factory MealsState({MealData? meal}) = _MealsState;
}

@freezed
abstract class MealsEffect with _$MealsEffect {
  const factory MealsEffect.openAddMealPage() = _OpenAddMealPageEffect;
}
