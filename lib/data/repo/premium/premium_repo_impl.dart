import 'package:calora/data/api/premium_api.dart';
import 'package:calora/data/store/auth/auth_store.dart';
import 'package:calora/domain/model/premium/my_subscription_order_model.dart';
import 'package:calora/domain/model/premium/premium_plan_model.dart';
import 'package:calora/domain/model/premium/promo_code_model.dart';
import 'package:calora/domain/model/premium/subscription_response_model.dart';
import 'package:calora/domain/repo/premium/premium_repo.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: PremiumRepo)
class PremiumRepoImpl implements PremiumRepo {
  final PremiumApi _api;
  final AuthStore _authStore;

  PremiumRepoImpl(this._api, this._authStore);

  @override
  Future<bool> get isUzbekistan async =>
      await _authStore.isCountryUzbekistan() ?? false;

  @override
  Future<void> deleteOrder({required int orderId}) async =>
      await _api.deleteOrder(orderId: orderId);

  @override
  Future<List<MySubscriptionOrderModel>> getMyOrders() async =>
      await _api.getMyOrders();

  @override
  Future<String> getPaymentLink({required int orderId}) async =>
      await _api.getPaymentLink(orderId: orderId);

  @override
  Future<SubscriptionResponseModel> orderSubscription({
    required String provider,
    required String plan,
    required int orderMonth,
    int? couponId,
  }) async {
    return _api.orderSubscription(
      provider: provider,
      plan: plan,
      orderMonth: orderMonth,
      couponId: couponId,
    );
  }

  @override
  Future<List<PremiumPlanModel>> getPremiumPlans() async =>
      await _api.getPremiumPlans();

  @override
  Future<PromoCodeModel> getPromoCodeAmount({required String code}) async =>
      await _api.getPromoCodeAmount(code: code);
}
