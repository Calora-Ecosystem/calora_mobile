import 'package:calora/domain/model/premium/family_code.dart';
import 'package:calora/domain/model/premium/my_subscription.dart';
import 'package:calora/domain/model/premium/my_subscription_order_model.dart';
import 'package:calora/domain/model/premium/premium_plan_model.dart';
import 'package:calora/domain/model/premium/promo_code_model.dart';
import 'package:calora/domain/model/premium/subscription_response_model.dart';

abstract class PremiumRepo {
  Future<SubscriptionResponseModel> orderSubscription({
    required String provider,
    required String plan,
    required int orderMonth,
    int? couponId,
  });

  Future<void> deleteOrder({required int orderId});

  Future<String> getPaymentLink({required int orderId});

  Future<List<MySubscriptionOrderModel>> getMyOrders();

  Future<List<PremiumPlanModel>> getPremiumPlans({bool family = false});

  Future<MySubscription> getMySubscription();

  Future<PromoCodeModel> getPromoCodeAmount({required String code});

  /// Family plan: codes the buyer got for the second person, newest first.
  Future<List<FamilyCode>> getFamilyCodes();

  /// Family plan: the second person redeems the code and gets Premium.
  Future<FamilyRedeemResult> redeemFamilyCode(String code);
}
