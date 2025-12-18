import 'package:calora/domain/model/calories/calories_data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'calories_management.freezed.dart';

@freezed
abstract class CaloriesState with _$CaloriesState {
  const factory CaloriesState({
    @Default(false) bool isScrolled,
    @Default(0) double plan,
    @Default(0) double consumed,
    @Default(0) double leftover,
    @Default([]) List<MealData> meals,
    @Default(false) bool isLoading,
    DateTime? date,
  }) = _CaloriesState;

  factory CaloriesState.initial() => CaloriesState(date: DateTime.now());
}

@freezed
abstract class CaloriesEffect with _$CaloriesEffect {
  const factory CaloriesEffect.openMealPage(MealType type, List<MealData> meals, DateTime dateTime) = _CaloriesEffect;
}
