import 'package:calora/common/gen/assets.gen.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'premium_management.freezed.dart';

@freezed
abstract class PremiumState with _$PremiumState {
  const factory PremiumState({
    @Default([]) List<Plan> plans,
    @Default([]) List<PaymentMethod> paymentMethods,
    @Default(-1) int selectedPlanIndex,
    @Default(-1) int selectedPaymentMethodIndex,
    @Default(false) bool isLoading,
  }) = _PremiumState;
}

@freezed
class PremiumEffect with _$PremiumEffect {
  const factory PremiumEffect() = _PremiumEffect;
}

class Plan {
  final String title;
  final int price;
  final int actualPrice;
  final bool isMostPopular;

  Plan({
    required this.title,
    required this.price,
    required this.actualPrice,
    this.isMostPopular = false,
  });
}

class PaymentMethod {
  final SvgGenImage icon;
  final String? displayName;
  final String code;

  PaymentMethod({required this.icon, this.displayName, required this.code});
}