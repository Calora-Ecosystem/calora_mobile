import 'package:calora/domain/model/meal/food/food_models.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'food_request.freezed.dart';
part 'food_request.g.dart';

@freezed
abstract class FoodRequest with _$FoodRequest {
  const factory FoodRequest({
    @JsonKey(includeIfNull: false) int? categoryId,
    required FoodName name,
    required String coverUrl,
    String? description,
    required List<Metric> metrics,
    required int userId,
  }) = _FoodRequest;

  factory FoodRequest.fromJson(Map<String, dynamic> json) => _$FoodRequestFromJson(json);
}
