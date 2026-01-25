import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/domain/model/premium/my_subscription_order_model.dart';
import 'package:calora/domain/model/premium/premium_plan_model.dart';
import 'package:calora/domain/model/premium/promo_code_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'premium_management.freezed.dart';

@freezed
abstract class PremiumState with _$PremiumState {
  const factory PremiumState({
    @Default([]) List<PlanModel> plans,
    @Default([]) List<PaymentMethod> paymentMethods,
    PlanModel? selectedPlan,
    PaymentMethod? selectedPaymentMethod,
    @Default(false) bool isGettingOrders,
    @Default(false) bool isOrderingSubscription,
    @Default(false) bool isDeletingOrder,
    @Default(false) bool isGettingPaymentLink,
    @Default(false) bool isGettingPremiumPlans,
    @Default(false) bool isGettingPromoCodeValue,
    @Default(false) bool isPaymentPending,
    @Default(const []) List<MySubscriptionOrderModel> myOrders,
    @Default('') String paymentLink,
    PromoCodeModel? promoCodeValue,
  }) = _PremiumState;
}

@freezed
sealed class PremiumEffect with _$PremiumEffect {
  const factory PremiumEffect.openPaymentUrlFailure(String error) = _OpenPaymentUrlFailure;
  const factory PremiumEffect.deleteSubscriptionFailure(String error) = _DeleteSubscriptionFailure;
  const factory PremiumEffect.invalidPromoCode() = _InvalidPromoCode;
  const factory PremiumEffect.subscriptionSuccess() = _SubscriptionSuccess;
}

@immutable
class PlanModel {
  final String title;
  final int price;
  final int? actualPrice;
  final bool isMostPopular;
  final int packageMonth;

  const PlanModel({
    required this.title,
    required this.price,
    this.actualPrice,
    this.isMostPopular = false,
    required this.packageMonth,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanModel &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          price == other.price &&
          actualPrice == other.actualPrice &&
          isMostPopular == other.isMostPopular &&
          packageMonth == other.packageMonth;

  @override
  int get hashCode =>
      title.hashCode ^ price.hashCode ^ actualPrice.hashCode ^ isMostPopular.hashCode ^ packageMonth.hashCode;
}

@immutable
class PaymentMethod {
  final SvgGenImage icon;
  final String? displayName;
  final String code;

  const PaymentMethod({required this.icon, this.displayName, required this.code});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentMethod &&
          runtimeType == other.runtimeType &&
          icon == other.icon &&
          displayName == other.displayName &&
          code == other.code;

  @override
  int get hashCode => icon.hashCode ^ displayName.hashCode ^ code.hashCode;
}
