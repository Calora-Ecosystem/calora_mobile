import 'package:freezed_annotation/freezed_annotation.dart';

part 'calories_data.freezed.dart';
part 'calories_data.g.dart';

enum MealType { Breakfast, Lunch, Snack, Dinner }

@freezed
abstract class MealData with _$MealData {
  const factory MealData({
    required double max,
    required double value,
    required MealType type,
    required double mass,
    required double oils,
    required double proteins,
    required double carbohydrates,
  }) = _MealData;

  factory MealData.fromJson(Map<String, dynamic> json) => _$MealDataFromJson(json);
}

@freezed
abstract class DailyCalories with _$DailyCalories {
  const factory DailyCalories({required double plan, required double consumed, required double leftover}) =
      _DailyCalories;

  factory DailyCalories.fromJson(Map<String, dynamic> json) => _$DailyCaloriesFromJson(json);
}
