import 'package:calora/domain/model/meal/food/food_models.dart';
import 'package:calora/domain/model/pagination/paginated_response.dart';
import 'package:calora/domain/model/premium/family_code.dart';
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
      final page = PaginatedResponse<FoodModel>.fromJson(
        {
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
        },
        (json) => FoodModel.fromJson(json as Map<String, dynamic>),
      );
      expect(page.content!.map((f) => f.name), ['Uy salati', 'Osh']);
      expect(page.content!.last.categoryId, 3);
    });
  });

  group('family plan', () {
    test('FamilyCode parses every status', () {
      FamilyCode parse(String status) => FamilyCode.fromJson({
        'code': 'FAMILY-AB12CD',
        'months': 1,
        'status': status,
        'expireAt': '2026-10-31T12:00:00',
        'redeemedBy': status == 'Redeemed' ? 'Vali' : null,
      });

      expect(parse('Active').status, FamilyCodeStatus.active);
      expect(parse('Redeemed').status, FamilyCodeStatus.redeemed);
      expect(parse('Redeemed').redeemedBy, 'Vali');
      expect(parse('Expired').status, FamilyCodeStatus.expired);
      expect(parse('Active').expireAt, DateTime(2026, 10, 31, 12));
    });

    test('redeem result asks for a token refresh by default', () {
      final result = FamilyRedeemResult.fromJson({
        'ownerName': 'Ali',
        'months': 1,
        'endsAt': '2026-11-01T10:00:00',
      });
      expect(result.ownerName, 'Ali');
      expect(result.requiresTokenRefresh, isTrue);
    });

    test('a family payment is done once a new active code appears', () {
      const old = FamilyCode(code: 'FAMILY-OLD111');
      const fresh = FamilyCode(code: 'FAMILY-NEW222');
      const used = FamilyCode(
        code: 'FAMILY-USE333',
        status: FamilyCodeStatus.redeemed,
      );
      // A Premium user's old unused code from last month isn't proof.
      expect(PremiumManager.familyCodeIssued({'FAMILY-OLD111'}, [old]), isFalse);
      expect(
        PremiumManager.familyCodeIssued({'FAMILY-OLD111'}, [fresh, old]),
        isTrue,
      );
      expect(PremiumManager.familyCodeIssued({}, [fresh]), isTrue);
      expect(PremiumManager.familyCodeIssued({}, [used]), isFalse);
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
  });
}
