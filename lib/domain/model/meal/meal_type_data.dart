import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'meal_type_data.freezed.dart';

enum MealCategory { liquid, pureed, drinks, breakfast, fastFood }

@freezed
abstract class MealTypeData with _$MealTypeData {
  const factory MealTypeData({required String name, required Widget image, required MealCategory type}) = _MealTypeData;
}
