import 'package:calora/domain/model/meal/food/food_models.dart';
import 'package:calora/domain/model/pagination/paginated_response.dart';
import 'package:calora/domain/model/premium/family_code.dart';
import 'package:calora/domain/model/premium/family_coupon.dart';
import 'package:calora/domain/model/premium/my_subscription.dart';
import 'package:calora/presentation/premium/management/premium_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FoodModel', () {
    // A user's own food: manual "Create" has no category, and an older
    // backend sent null for it (and for a missing cover) — one such item
    // used to fail the whole "Last eaten" / "My foods" page.
    final ownFood = {
      'id': 41,
      'name': 'Uy salati',
      'categoryId': null,
      'categoryName': null,
      'coverUrl': null,
      'metrics': [
        {'metric': 'Kcal', 'value': 120},
      ],
      'isUserFood': true,
      'isFavourite': false,
    };

    test('parses a food without category or cover', () {
      final food = FoodModel.fromJson(ownFood);
      expect(food.categoryId, isNull);
      expect(food.coverUrl, isEmpty);
      expect(food.isUserFood, isTrue);
    });

    test('one uncategorised food no longer breaks the page', () {
      final page = PaginatedResponse<FoodModel>.fromJson({
        'content': [
          ownFood,
          {
            'id': 7,
            'name': 'Osh',
            'categoryId': 3,
            'coverUrl': 'images/osh.png',
            'metrics': <Object>[],
          },
        ],
        'total': 2,
      }, (json) => FoodModel.fromJson(json as Map<String, dynamic>));
      expect(page.content!.map((f) => f.name), ['Uy salati', 'Osh']);
      expect(page.content!.last.categoryId, 3);
    });
  });

  group('family plan', () {
    test('coupons/my parses every status and who used it', () {
      FamilyCoupon parse(
        String status, {
        Map<String, dynamic> extra = const {},
      }) => FamilyCoupon.fromJson({
        'id': 7,
        'code': 'FAMILY-AB12CD',
        'amount': 4900000,
        'isActive': true,
        'expireAt': '2026-10-31T12:00:00Z',
        'createdAt': '2026-10-01T12:00:00Z',
        'status': status,
        ...extra,
      });

      expect(parse('Active').status, FamilyCodeStatus.active);
      expect(parse('Expired').status, FamilyCodeStatus.expired);
      final viaList = parse(
        'Redeemed',
        extra: {
          'usedByUsers': [
            {'userId': 5, 'name': 'Vali', 'phone': '998901234567'},
          ],
        },
      );
      expect(viaList.status, FamilyCodeStatus.redeemed);
      expect(viaList.redeemedBy, 'Vali');
      final viaFields = parse(
        'Redeemed',
        extra: {
          'usedByUsers': <Object>[],
          'usedByUserId': 5,
          'usedByName': 'Vali',
        },
      );
      expect(viaFields.usedByUsers.single.userId, 5);
      expect(viaFields.redeemedBy, 'Vali');
      expect(parse('Active').redeemedBy, isNull);
      expect(
        parse('Active').expireAt,
        DateTime.utc(2026, 10, 31, 12).toLocal(),
      );
    });

    test('family codes are told apart from other promo codes', () {
      expect(isFamilyCode('FAMILY-AB12CD'), isTrue);
      expect(isFamilyCode(' family-ab12cd '), isTrue);
      expect(isFamilyCode('FAMILYAB12'), isTrue);
      expect(isFamilyCode('SALE50'), isFalse);
    });

    test('a family payment is done once a new active coupon appears', () {
      const old = FamilyCoupon(id: 1, code: 'FAMILY-OLD111');
      const fresh = FamilyCoupon(id: 2, code: 'FAMILY-NEW222');
      const used = FamilyCoupon(
        id: 3,
        code: 'FAMILY-USE333',
        status: FamilyCodeStatus.redeemed,
      );
      expect(PremiumManager.newFamilyCoupon({'FAMILY-OLD111'}, [old]), isNull);
      expect(
        PremiumManager.newFamilyCoupon({'FAMILY-OLD111'}, [fresh, old]),
        fresh,
      );
      expect(PremiumManager.newFamilyCoupon({}, [fresh]), fresh);
      expect(PremiumManager.newFamilyCoupon({}, [used]), isNull);
    });

    test('subscription/my reports the family plan', () {
      final sub = MySubscription.fromJson({
        'isPremium': true,
        'status': 'Active',
        'source': 'Payment',
        'durationInMonths': 1,
        'isFamily': true,
      });
      expect(sub.isFamily, isTrue);
      expect(MySubscription.fromJson({}).isFamily, isFalse);
    });

    test('subscription/my reads the plan field the backend sends', () {
      final family = MySubscription.fromJson({
        'plan': 'Family',
        'isPremium': false,
        'isActive': true,
        'status': 'Active',
      });
      expect(family.isFamily, isTrue);
      expect(family.isPremium, isTrue);

      final free = MySubscription.fromJson({
        'plan': 'Free',
        'isPremium': false,
        'isActive': false,
        'status': 'Free',
      });
      expect(free.isPremium, isFalse);
      expect(free.status, SubscriptionStatus.free);
    });
  });
}
