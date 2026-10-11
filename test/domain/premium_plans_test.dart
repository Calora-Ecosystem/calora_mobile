import 'package:calora/common/enums/subscription_plan_type.dart';
import 'package:calora/domain/model/premium/premium_plan_model.dart';
import 'package:calora/domain/model/premium/subscription_response_model.dart';
import 'package:calora/domain/repo/common/common_repo.dart';
import 'package:calora/domain/repo/premium/premium_repo.dart';
import 'package:calora/presentation/premium/management/premium_manager.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/premium_plans.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final plans = PremiumPlanModel.listFromJson(backendPlans);

  group('PremiumPlanModel', () {
    test('reads the plan type and features', () {
      final family = plans.singleWhere((plan) => plan.id == 8);
      expect(family.type, SubscriptionPlanType.family);
      expect(family.isFamily, isTrue);
      expect(family.price, 70000);
      expect(family.originalFee, 98000);
      expect(family.features.single.key, 'AiScans');
      expect(family.features.single.value, 'unlimited');
      expect(plans.first.type, SubscriptionPlanType.free);
    });

    test('charges the referral price only when the discount is on', () {
      final discounted = PremiumPlanModel.fromJson({
        'id': 1,
        'plan': 'Premium',
        'fee': 49000,
        'referralDiscountPercent': 20,
        'discountedFee': 39200,
      });
      expect(discounted.price, 39200);
      expect(
        PremiumPlanModel.fromJson({
          'id': 1,
          'fee': 49000,
          'discountedFee': 39200,
        }).price,
        49000,
      );
    });
  });

  group('PlanGroup', () {
    test('groups the backend list by plan, Free left out', () {
      final groups = PlanGroup.of(plans);
      expect(groups.map((group) => group.type), [
        SubscriptionPlanType.premium,
        SubscriptionPlanType.family,
      ]);
      expect(groups.first.packages.map((p) => p.id), [4, 3]);
      expect(groups.last.packages.map((p) => p.id), [8]);
    });

    test('one package per duration — the stale 70 000 monthly is dropped', () {
      final premium = PlanGroup.of(plans).first;
      expect(premium.byDuration(1)?.fee, 49000);
      expect(premium.packages.where((p) => p.id == 5), isEmpty);
    });

    test('inactive packages and unknown plans are not sold', () {
      final groups = PlanGroup.of([
        const PremiumPlanModel(id: 1, isActive: false),
        const PremiumPlanModel(id: 2, type: SubscriptionPlanType.pro),
        const PremiumPlanModel(id: 3, duration: 12, fee: 1),
      ]);
      expect(groups.single.packages.single.id, 3);
      expect(PlanGroup.of(const []), isEmpty);
    });
  });

  group('PremiumManager', () {
    late _FakePremiumRepo repo;
    late PremiumManager manager;
    final groups = PlanGroup.of(plans);

    setUp(() {
      repo = _FakePremiumRepo();
      manager = PremiumManager(repo, _FakeCommonRepo());
    });

    tearDown(() => manager.close());

    test('shows the picked package of the regular plan', () {
      manager.showPlans(groups.first.packages, selectedId: 3);
      expect(manager.state.isFamily, isFalse);
      expect(manager.state.plans.map((plan) => plan.id), [4, 3]);
      expect(manager.state.selectedPlan?.id, 3);
    });

    test('falls back to the popular package', () {
      manager.showPlans(groups.first.packages);
      expect(manager.state.selectedPlan?.id, 4);
    });

    test('family packages switch the sheet to the family plan', () {
      manager.showPlans(groups.last.packages, selectedId: 8);
      expect(manager.state.isFamily, isTrue);
      expect(manager.state.selectedPlan?.price, 70000);
      expect(manager.state.selectedPlan?.originalFee, 98000);
    });

    test('orders the family package as a Family plan', () async {
      manager.showPlans(groups.last.packages, selectedId: 8);
      await manager.orderSubscription();
      expect(repo.orderedPlan, 'Family');
      expect(repo.orderedPackageId, 8);
    });

    test('orders a regular package as a Premium plan', () async {
      manager.showPlans(groups.first.packages, selectedId: 3);
      await manager.orderSubscription();
      expect(repo.orderedPlan, 'Premium');
      expect(repo.orderedPackageId, 3);
    });
  });
}

class _FakePremiumRepo implements PremiumRepo {
  String? orderedPlan;
  int? orderedPackageId;

  @override
  Future<SubscriptionResponseModel> orderSubscription({
    required String provider,
    required String plan,
    required int orderMonth,
    int? couponId,
  }) async {
    orderedPlan = plan;
    orderedPackageId = orderMonth;
    throw StateError('not paying in tests');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCommonRepo implements CommonRepo {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
