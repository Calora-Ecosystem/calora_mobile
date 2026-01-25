import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_response_model.freezed.dart';
part 'subscription_response_model.g.dart';

@freezed
sealed class SubscriptionResponseModel with _$SubscriptionResponseModel {
  const factory SubscriptionResponseModel({bool? paymentRequired, String? paymentLink}) = _SubscriptionResponseModel;

  factory SubscriptionResponseModel.fromJson(Map<String, dynamic> json) => _$SubscriptionResponseModelFromJson(json);
}
