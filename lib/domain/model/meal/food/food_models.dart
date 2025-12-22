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

  factory FoodModel.fromJson(Map<String, dynamic> json) => _$FoodModelFromJson(json);
}

@freezed
abstract class Metric with _$Metric {
  const factory Metric({int? userId, required String metric, required num value}) = _Metric;

  factory Metric.fromJson(Map<String, dynamic> json) => _$MetricFromJson(json);
}

@freezed
abstract class ScannerFood with _$ScannerFood {
  const factory ScannerFood({
    required String name,
    required int weight,
    required List<Metric> metrics,
  }) = _ScannerFood;

  factory ScannerFood.fromJson(Map<String, dynamic> json) => _$ScannerFoodFromJson(json);
}
