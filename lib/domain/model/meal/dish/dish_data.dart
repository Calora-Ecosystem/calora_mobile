import 'package:calora/domain/model/meal/meal_type_data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'dish_data.freezed.dart';

@freezed
abstract class DishData with _$DishData {
  const factory DishData({
    required String name,
    required String imageUrl,
    required String description,
    required MealCategory type,
    required double oils,
    required double proteins,
    required double carbohydrates,
  }) = _DishData;
}
