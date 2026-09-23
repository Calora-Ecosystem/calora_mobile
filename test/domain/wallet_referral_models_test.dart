import 'package:calora/domain/model/calories/ai_quota.dart';
import 'package:calora/domain/model/coins/coin_transaction.dart';
import 'package:calora/domain/model/coins/market_item.dart';
import 'package:calora/domain/model/coins/wallet.dart';
import 'package:calora/domain/model/group/step_group.dart';
import 'package:calora/domain/model/premium/my_subscription.dart';
import 'package:calora/domain/model/referral/referral_info.dart';
import 'package:flutter_test/flutter_test.dart';

/// Payloads below are copied from real backend responses (staging build), so
/// these tests pin the JSON contract the app relies on.
void main() {
  test('wallet', () {
    final wallet = Wallet.fromJson({
      'balance': 4,
      'totalEarned': 4,
      'totalSpent': 0,
      'availableCalora': 748,
      'earnedCalora': 4748,
      'caloraExchanged': 4000,
      'caloraPerCoin': 1000,
      'maxExchangeableCoins': 0,
    });
    expect(wallet.balance, 4);
    expect(wallet.availableCalora, 748);
    expect(wallet.caloraPerCoin, 1000);
  });

  test('coin transaction sign decides earn / spend', () {
    final spend = CoinTransaction.fromJson({
      'id': 7,
      'title': 'mi_premium_7',
      'amount': -90,
      'type': 'Purchase',
      'calora': null,
      'createdAt': '2026-09-23T16:43:11.148209',
    });
    expect(spend.type, CoinTxType.spend);
    expect(spend.amount, -90);
    expect(spend.date.year, 2026);
  });

  test('market item enums', () {
    final item = MarketItem.fromJson({
      'id': 3,
      'title': 'mi_ai_pack',
      'subtitle': 'mi_ai_pack_sub',
      'priceCoins': 50,
      'category': 'Boost',
      'rewardType': 'AiScans',
      'rewardValue': 10,
      'isPopular': false,
    });
    expect(item.category, MarketCategory.boost);
    expect(item.rewardType, MarketRewardType.aiScans);
    expect(item.rewardValue, 10);
  });

  test('step group detail with ranked members', () {
    final group = StepGroup.fromJson({
      'members': [
        {
          'userId': 1,
          'name': 'Ali',
          'photo': null,
          'steps': 100000.0,
          'index': 1,
          'isMe': false,
          'isOwner': true,
          'joinedAt': '2026-09-23T16:43:25.593424',
        },
        {
          'userId': 2,
          'name': 'Vali',
          'photo': null,
          'steps': 12000.0,
          'index': 2,
          'isMe': true,
          'isOwner': false,
          'joinedAt': '2026-09-23T16:43:25.991504',
        },
      ],
      'id': 1,
      'name': 'Oila challenge',
      'inviteCode': 'CAL-4FCDZ',
      'ownerId': 1,
      'isOwner': false,
      'memberCount': 2,
      'totalSteps': 112000.0,
      'createdAt': '2026-09-23T16:43:25.593424',
    });
    expect(group.id, '1');
    expect(group.isOwner, isFalse);
    expect(group.totalSteps, 112000);
    expect(group.members.first.userId, 1);
    expect(group.members.last.isMe, isTrue);
  });

  test('referral info and invited friends', () {
    final info = ReferralInfo.fromJson({
      'code': 'CALORA-J7HY',
      'invited': 5,
      'active': 4,
      'friendsGoal': 5,
      'premiumDays': 30,
      'progressFriends': 4,
      'friendsLeft': 1,
      'progress': 0.8,
      'premiumsEarned': 0,
      'isReferred': false,
      'referredBy': null,
      'canApplyCode': true,
      'discountPercent': 10,
      'hasDiscount': false,
    });
    expect(info.progressFriends, 4);
    expect(info.friendsLeft, 1);
    expect(info.canApplyCode, isTrue);

    final friend = ReferredFriend.fromJson({
      'userId': 5,
      'name': 'Friend5',
      'photo': null,
      'status': 'Active',
      'joinedAt': '2026-09-23T17:08:13.933255',
      'activatedAt': '2026-09-23T17:08:14.905899',
    });
    expect(friend.status, ReferredFriendStatus.active);
    expect(friend.activatedAt, isNotNull);

    final joined = ReferredFriend.fromJson({
      'userId': 6,
      'name': 'U6',
      'status': 'Joined',
      'joinedAt': '2026-09-23T17:08:14.062265',
      'activatedAt': null,
    });
    expect(joined.status, ReferredFriendStatus.joined);
  });

  test('subscription granted by referral', () {
    final sub = MySubscription.fromJson({
      'plan': 'Premium',
      'isPremium': true,
      'isActive': true,
      'source': 'Referral',
      'startsAt': '2026-09-23T17:08:15.642573',
      'endsAt': '2026-10-23T17:08:15.642573',
      'daysLeft': 30,
      'provider': null,
      'durationInMonths': null,
      'autoRenew': false,
      'nextPaymentAt': null,
    });
    expect(sub.isPremium, isTrue);
    expect(sub.source, 'Referral');
    expect(sub.daysLeft, 30);
    expect(sub.nextPaymentAt, isNull);
  });

  test('ai quota', () {
    final quota = AiQuota.fromJson({
      'isPremium': false,
      'unlimited': false,
      'limit': 5,
      'used': 5,
      'remaining': 0,
    });
    expect(quota.canUse, isFalse);
    expect(const AiQuota(unlimited: true, remaining: 0).canUse, isTrue);
  });
}
