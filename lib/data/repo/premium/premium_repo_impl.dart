import 'package:calora/common/enums/subscription_plan_type.dart';
import 'package:calora/data/api/premium_api.dart';
import 'package:calora/domain/model/premium/family_code.dart';
import 'package:calora/domain/model/premium/family_coupon.dart';
import 'package:calora/domain/model/premium/my_subscription.dart';
import 'package:calora/domain/model/premium/my_subscription_order_model.dart';
import 'package:calora/domain/model/premium/premium_plan_model.dart';
import 'package:calora/domain/model/premium/promo_code_model.dart';
import 'package:calora/domain/model/premium/subscription_response_model.dart';
import 'package:calora/domain/repo/premium/premium_repo.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: PremiumRepo)
class PremiumRepoImpl implements PremiumRepo {
  final PremiumApi _api;

  PremiumRepoImpl(this._api);

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
  Future<List<PremiumPlanModel>> getPremiumPlans() => _api.getPremiumPlans();

  @override
  Future<MySubscription> getMySubscription() => _api.getMySubscription();

  @override
  Future<PromoCodeModel> getPromoCodeAmount({required String code}) async =>
      await _api.getPromoCodeAmount(code: code);

  @override
  Future<FamilyRedeemResult> redeemFamilyCode(String code) async {
    final coupon = await _api.getPromoCodeAmount(code: code.trim());
    final couponId = coupon.id;
    if (couponId == null) {
      throw const FamilyCodeException(FamilyCodeException.notFound);
    }
    final expireAt = DateTime.tryParse(coupon.expireAt ?? '');
    if (expireAt != null && expireAt.isBefore(DateTime.now())) {
      throw const FamilyCodeException(FamilyCodeException.expired);
    }
    if (coupon.isActive == false) {
      throw const FamilyCodeException(FamilyCodeException.used);
    }
    if (await _isOwnCoupon(code)) {
      throw const FamilyCodeException(FamilyCodeException.self);
    }

    final premium = PlanGroup.of(
      await _api.getPremiumPlans(),
    ).firstWhereOrNull((group) => group.type.isPremium);
    final package = premium?.packages.firstWhereOrNull(
      (package) => package.price <= coupon.sum,
    );
    if (package == null) {
      throw const FamilyCodeException(FamilyCodeException.notCovered);
    }

    final order = await _api.orderSubscription(
      provider: 'Payme',
      plan: SubscriptionPlanType.premium.toApi(),
      orderMonth: package.id,
      couponId: couponId,
    );
    if (order.paymentRequired ?? true) {
      throw const FamilyCodeException(FamilyCodeException.notCovered);
    }
    return FamilyRedeemResult(months: package.duration);
  }

  Future<bool> _isOwnCoupon(String code) async {
    try {
      final own = await _api.getMyCoupons();
      final normalized = code.trim().toUpperCase();
      return own.any((coupon) => coupon.code.toUpperCase() == normalized);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<FamilyCoupon>> getMyCoupons() => _api.getMyCoupons();
}
