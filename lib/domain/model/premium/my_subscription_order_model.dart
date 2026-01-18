import 'package:freezed_annotation/freezed_annotation.dart';

part 'my_subscription_order_model.freezed.dart';
part 'my_subscription_order_model.g.dart';

@freezed
sealed class MySubscriptionOrderModel with _$MySubscriptionOrderModel {
  const factory MySubscriptionOrderModel({
    int? id,
    String? status,
    int? amount,
    String? type,
    String? provider,
    String? createdAt,
    String? updatedAt,
  }) = _MySubscriptionOrderModel;

  factory MySubscriptionOrderModel.fromJson(Map<String, dynamic> json) => _$MySubscriptionOrderModelFromJson(json);

  static List<MySubscriptionOrderModel> listFromJson(List<dynamic> json) {
    return json.whereType<Map<String, dynamic>>().map(MySubscriptionOrderModel.fromJson).toList();
  }
}
