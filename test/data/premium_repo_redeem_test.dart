import 'package:calora/data/api/premium_api.dart';
import 'package:calora/data/repo/premium/premium_repo_impl.dart';
import 'package:calora/domain/model/premium/family_code.dart';
import 'package:calora/domain/model/premium/family_coupon.dart';
import 'package:calora/domain/model/premium/premium_plan_model.dart';
import 'package:calora/domain/model/premium/promo_code_model.dart';
import 'package:calora/domain/model/premium/subscription_response_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/premium_plans.dart';

void main() {
  late _FakePremiumApi api;
  late PremiumRepoImpl repo;

  setUp(() {
    api = _FakePremiumApi();
    repo = PremiumRepoImpl(api);
  });

  Matcher failsWith(String code) =>
      throwsA(isA<FamilyCodeException>().having((e) => e.code, 'code', code));

  test('a family coupon buys the Premium package it covers for free', () async {
    api.coupon = const PromoCodeModel(id: 11, amount: 7000000, isActive: true);
    final result = await repo.redeemFamilyCode(' FAMILY-AB12CD ');
    expect(api.checkedCode, 'FAMILY-AB12CD');
    expect(api.order, (
      provider: 'Payme',
      plan: 'Premium',
      packageId: 3,
      couponId: 11,
    ));
    expect(result.months, 1);
    expect(result.requiresTokenRefresh, isTrue);
  });

  test('a bigger coupon takes the longest package it covers', () async {
    api.coupon = const PromoCodeModel(id: 12, amount: 39900000);
    final result = await repo.redeemFamilyCode('FAMILY-YEAR12');
    expect(api.order?.packageId, 4);
    expect(result.months, 12);
  });

  test('an unknown code never creates an order', () async {
    api.coupon = const PromoCodeModel();
    await expectLater(
      repo.redeemFamilyCode('FAMILY-NOPE00'),
      failsWith(FamilyCodeException.notFound),
    );
    expect(api.order, isNull);
  });

  test('used, expired and own codes are refused before ordering', () async {
    api.coupon = const PromoCodeModel(id: 1, amount: 7000000, isActive: false);
    await expectLater(
      repo.redeemFamilyCode('FAMILY-USED11'),
      failsWith(FamilyCodeException.used),
    );

    api.coupon = const PromoCodeModel(
      id: 1,
      amount: 7000000,
      expireAt: '2020-01-01T00:00:00Z',
    );
    await expectLater(
      repo.redeemFamilyCode('FAMILY-OLD111'),
      failsWith(FamilyCodeException.expired),
    );

    api.coupon = const PromoCodeModel(id: 1, amount: 7000000);
    api.ownCoupons = const [FamilyCoupon(id: 1, code: 'FAMILY-MINE11')];
    await expectLater(
      repo.redeemFamilyCode('family-mine11'),
      failsWith(FamilyCodeException.self),
    );
    expect(api.order, isNull);
  });

  test('a coupon too small for any package is not spent', () async {
    api.coupon = const PromoCodeModel(id: 1, amount: 100000);
    await expectLater(
      repo.redeemFamilyCode('FAMILY-TINY11'),
      failsWith(FamilyCodeException.notCovered),
    );
    expect(api.order, isNull);
  });

  test('a backend that still asks for payment is reported', () async {
    api
      ..coupon = const PromoCodeModel(id: 1, amount: 7000000)
      ..paymentRequired = true;
    await expectLater(
      repo.redeemFamilyCode('FAMILY-PAY111'),
      failsWith(FamilyCodeException.notCovered),
    );
  });
}

typedef _Order = ({String provider, String plan, int packageId, int? couponId});

class _FakePremiumApi extends PremiumApi {
  _FakePremiumApi() : super(Dio());

  PromoCodeModel coupon = const PromoCodeModel();
  List<FamilyCoupon> ownCoupons = const [];
  bool paymentRequired = false;
  String? checkedCode;
  _Order? order;

  @override
  Future<PromoCodeModel> getPromoCodeAmount({required String code}) async {
    checkedCode = code;
    return coupon;
  }

  @override
  Future<List<PremiumPlanModel>> getPremiumPlans() async =>
      PremiumPlanModel.listFromJson(backendPlans);

  @override
  Future<List<FamilyCoupon>> getMyCoupons() async => ownCoupons;

  @override
  Future<SubscriptionResponseModel> orderSubscription({
    required String provider,
    required String plan,
    required int orderMonth,
    int? couponId,
  }) async {
    order = (
      provider: provider,
      plan: plan,
      packageId: orderMonth,
      couponId: couponId,
    );
    return SubscriptionResponseModel(paymentRequired: paymentRequired);
  }
}
