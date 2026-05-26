import 'package:flutter/cupertino.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'food_models.freezed.dart';
part 'food_models.g.dart';

@freezed
abstract class FoodModel with _$FoodModel {
  const factory FoodModel({
    int? id,
    required String name,
    required int categoryId,
    String? categoryName,
    String? description,
    required String coverUrl,
    required List<Metric> metrics,
    @Default(false) bool isUserFood,
    @Default(false) bool isFavourite,
    int? userId,
  }) = _FoodModel;

  factory FoodModel.fromJson(Map<String, dynamic> json) =>
      _$FoodModelFromJson(json);
}

@freezed
abstract class FoodName with _$FoodName {
  const factory FoodName({
    required String uz,
    required String ru,
    required String eng,
    required String cyrl,
  }) = _FoodName;

  factory FoodName.fromJson(Map<String, dynamic> json) =>
      _$FoodNameFromJson(json);
}

class FoodNameConverter implements JsonConverter<FoodName, Object> {
  const FoodNameConverter();

  @override
  FoodName fromJson(Object json) {
    if (json is String) {
      return FoodName(uz: json, ru: json, eng: json, cyrl: json);
    }
    return FoodName.fromJson(json as Map<String, dynamic>);
  }

  @override
  Map<String, dynamic> toJson(FoodName object) => object.toJson();
}

@freezed
abstract class Metric with _$Metric {
  const factory Metric({
    int? userId,
    required String metric,
    required num value,
  }) = _Metric;

  factory Metric.fromJson(Map<String, dynamic> json) => _$MetricFromJson(json);
}

@freezed
abstract class ScannerFood with _$ScannerFood {
  const factory ScannerFood({
    @FoodNameConverter() required FoodName name,
    required int categoryId,
    required int weight,
    required List<Metric> metrics,
  }) = _ScannerFood;

  factory ScannerFood.fromJson(Map<String, dynamic> json) =>
      _$ScannerFoodFromJson(json);
}

class MealInfo {
  final String title;
  final String value;
  final String max;
  final Widget image;
  final VoidCallback? onTap;

  MealInfo({
    required this.title,
    required this.value,
    required this.max,
    required this.image,
    required this.onTap,
  });
}
