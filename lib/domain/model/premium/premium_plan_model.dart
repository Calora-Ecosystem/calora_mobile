import 'package:freezed_annotation/freezed_annotation.dart';

part 'premium_plan_model.freezed.dart';
part 'premium_plan_model.g.dart';

@freezed
sealed class PremiumPlanModel with _$PremiumPlanModel {
  const factory PremiumPlanModel({
    int? id,
    int? duration,
    bool? isActive,
    String? plan,
    String? createdAt,
    int? fee,
    bool? isPopular,
  }) = _PremiumPlanModel;

  factory PremiumPlanModel.fromJson(Map<String, dynamic> json) => _$PremiumPlanModelFromJson(json);

  static List<PremiumPlanModel> listFromJson(List<dynamic> json) {
    return json.whereType<Map<String, dynamic>>().map(PremiumPlanModel.fromJson).toList();
  }
}
