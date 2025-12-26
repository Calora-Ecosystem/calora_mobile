import 'package:calora/domain/model/calories/calories_data.dart';
import 'package:calora/domain/model/meal/menu/menu_item.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'meals_management.freezed.dart';

@freezed
abstract class MealsState with _$MealsState {
  const factory MealsState({
    @Default([]) List<MenuItem> menuItems,
    @Default(false) bool isLoading,
    @Default(false) bool isSummary,
    MealData? meal,
    @Default([]) List<MealData> meals,
  }) = _MealsState;
}

@freezed
abstract class MealsEffect with _$MealsEffect {
  const factory MealsEffect.openAddMealPage() = _OpenAddMealPageEffect;
}
