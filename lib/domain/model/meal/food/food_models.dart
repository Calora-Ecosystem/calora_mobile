import 'package:freezed_annotation/freezed_annotation.dart';

part 'food_models.freezed.dart';
part 'food_models.g.dart';

@freezed
abstract class FoodItem with _$FoodItem {
  const factory FoodItem({
    required int id,
    required String name,
    required int categoryId,
    required String categoryName,
    String? description,
    required String coverUrl,
    required List<Metric> metrics,
    required bool isUserFood,
    int? userId,
  }) = _FoodItem;

  factory FoodItem.fromJson(Map<String, dynamic> json) => _$FoodItemFromJson(json);
}

@freezed
abstract class FoodListItem with _$FoodListItem {
  const factory FoodListItem({
    required int id,
    required String name,
    required int categoryId,
    required String categoryName,
    required String coverUrl,
    required List<Metric> metrics,
    required bool isUserFood,
  }) = _FoodListItem;

  factory FoodListItem.fromJson(Map<String, dynamic> json) => _$FoodListItemFromJson(json);
}

@freezed
abstract class Metric with _$Metric {
  const factory Metric({required int userId, required String metric, required num value}) = _Metric;

  factory Metric.fromJson(Map<String, dynamic> json) => _$MetricFromJson(json);
}
