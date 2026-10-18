import 'dart:convert';

import 'package:calora/common/di/network/interceptor/token_interceptor.dart';
import 'package:calora/common/service/premium_service.dart';
import 'package:calora/data/store/auth/auth_store.dart';
import 'package:calora/data/store/common/common_store.dart';
import 'package:calora/domain/model/premium/my_subscription.dart';
import 'package:calora/domain/model/token/token.dart';
import 'package:calora/domain/repo/premium/premium_repo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:rx_shared_preferences/rx_shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthStore auth;
  late CommonStore common;
  late _FakeTokens tokens;
  late _FakePremiumRepo repo;
  late PremiumService service;
  late DateTime time;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GetIt.instance.reset();
    GetIt.instance.registerSingleton(
      RxSharedPreferences(SharedPreferences.getInstance()),
    );
    auth = AuthStore();
    common = CommonStore();
    tokens = _FakeTokens(auth, common);
    repo = _FakePremiumRepo();
    time = DateTime(2026, 10, 17, 12);
    service = PremiumService(common, auth, tokens, repo)..now = () => time;
  });

  tearDown(() => service.dispose());

  group('isPremiumToken', () {
    test('any paid plan counts, in any letter case', () {
      for (final plan in ['Premium', 'premium', 'PREMIUM', 'Family', 'Pro']) {
        expect(
          PremiumService.isPremiumToken(_token(plan).accessToken),
          isTrue,
          reason: plan,
        );
      }
    });

    test('free, missing or unreadable plans do not', () {
      expect(PremiumService.isPremiumToken(_token('Free').accessToken), false);
      expect(PremiumService.isPremiumToken(_token(null).accessToken), false);
      expect(PremiumService.isPremiumToken('not-a-jwt'), isFalse);
      expect(PremiumService.isPremiumToken(null), isFalse);
    });

    test('an expired access token still tells the last known plan', () {
      final expired = _token('Premium', expired: true).accessToken;
      expect(PremiumService.isPremiumToken(expired), isTrue);
    });
  });

  group('sync', () {
    test(
      'the server unlocks Premium the stale token still calls free',
      () async {
        await auth.token.set(_token('Free'));
        repo.premium = true;
        tokens.issuePremium = true;

        expect(await service.sync(), isTrue);
        expect(await common.isUserPremium(), isTrue);
        expect(tokens.refreshes, 1);
        expect(
          PremiumService.isPremiumToken((await auth.token())?.accessToken),
          isTrue,
        );
      },
    );

    test('an ended subscription brings the banners back', () async {
      await auth.token.set(_token('Premium'));
      await common.isUserPremium.set(true);

      expect(await service.sync(), isFalse);
      expect(await common.isUserPremium(), isFalse);
      expect(tokens.refreshes, 1);
    });

    test('a token that already agrees is not refreshed', () async {
      await auth.token.set(_token('Premium'));
      repo.premium = true;

      expect(await service.sync(), isTrue);
      expect(tokens.refreshes, 0);
    });

    test('asks the server at most every 30 s unless forced', () async {
      await auth.token.set(_token('Free'));

      await service.sync();
      await service.sync();
      expect(repo.calls, 1);

      time = time.add(PremiumService.syncInterval);
      await service.sync();
      expect(repo.calls, 2);

      await service.sync(force: true);
      expect(repo.calls, 3);
    });

    test('calls made together share one request', () async {
      await auth.token.set(_token('Free'));
      await Future.wait([service.sync(force: true), service.sync(force: true)]);
      expect(repo.calls, 1);
    });

    test('offline keeps the last known state', () async {
      await auth.token.set(_token('Free'));
      await common.isUserPremium.set(true);
      repo.fail = true;

      expect(await service.sync(), isTrue);
      expect(await common.isUserPremium(), isTrue);
    });

    test('a signed-out user is never looked up', () async {
      expect(await service.sync(), isFalse);
      expect(repo.calls, 0);
    });
  });

  group('markPurchased', () {
    test(
      'a store purchase stays Premium while the backend catches up',
      () async {
        await auth.token.set(_token('Free'));

        await service.markPurchased();
        expect(await common.isUserPremium(), isTrue);
        expect(await service.sync(force: true), isTrue);
        expect(await common.isUserPremium(), isTrue);

        time = time.add(PremiumService.confirmWindow);
        expect(await service.sync(force: true), isFalse);
        expect(await common.isUserPremium(), isFalse);
      },
    );

    test('a purchase that cannot be confirmed offline stays Premium', () async {
      await auth.token.set(_token('Free'));
      await service.sync();
      repo.fail = true;
      service.confirmInterval = const Duration(milliseconds: 1);

      await service.markPurchased();
      time = time.add(PremiumService.confirmWindow);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(await common.isUserPremium(), isTrue);
    });

    test('a backend that never confirms ends the wait', () async {
      await auth.token.set(_token('Free'));
      service.confirmInterval = const Duration(milliseconds: 1);

      await service.markPurchased();
      time = time.add(PremiumService.confirmWindow);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(await common.isUserPremium(), isFalse);
    });

    test('the backend confirmation ends the wait for good', () async {
      await auth.token.set(_token('Free'));
      await service.markPurchased();

      repo.premium = true;
      tokens.issuePremium = true;
      expect(await service.sync(force: true), isTrue);

      time = time.add(PremiumService.confirmWindow);
      expect(await service.sync(force: true), isTrue);
      expect(await common.isUserPremium(), isTrue);
    });
  });

  group('token changes', () {
    test('sign-out clears Premium and sign-in asks the server', () async {
      await auth.token.set(_token('Premium'));
      await common.isUserPremium.set(true);
      repo.premium = true;
      service.start();
      await pumpEventQueue();
      expect(repo.calls, 1);

      await auth.token.set(null);
      await pumpEventQueue();
      expect(await common.isUserPremium(), isFalse);

      await auth.token.set(_token('Family'));
      await pumpEventQueue();
      expect(await common.isUserPremium(), isTrue);
      expect(repo.calls, 2);
    });

    test(
      'a refreshed token with a stale plan does not undo the server',
      () async {
        await auth.token.set(_token('Free'));
        repo.premium = true;
        service.start();
        await pumpEventQueue();
        expect(await common.isUserPremium(), isTrue);

        await auth.token.set(_token('Free'));
        await pumpEventQueue();
        expect(await common.isUserPremium(), isTrue);
      },
    );

    test('a refreshed token follows the plan the server agrees with', () async {
      await auth.token.set(_token('Free'));
      service.start();
      await pumpEventQueue();
      expect(await common.isUserPremium(), isFalse);

      repo.premium = true;
      time = time.add(PremiumService.syncInterval);
      await auth.token.set(_token('Premium'));
      await pumpEventQueue();
      expect(await common.isUserPremium(), isTrue);
    });
  });
}

Token _token(String? plan, {bool expired = false}) {
  String part(Map<String, Object> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  final exp = DateTime(expired ? 2020 : 2100).millisecondsSinceEpoch ~/ 1000;
  final payload = {'sub': '42', 'exp': exp, 'plan': ?plan};
  return Token(
    accessToken: '${part({'alg': 'HS256'})}.${part(payload)}.signature',
    refreshToken: 'refresh',
  );
}

class _FakeTokens extends TokenInterceptor {
  _FakeTokens(this._auth, CommonStore common)
    : super(_auth, Logger(level: Level.off), common);

  final AuthStore _auth;
  bool issuePremium = false;
  int refreshes = 0;

  @override
  Future<bool> refreshTokens() async {
    refreshes++;
    await _auth.token.set(_token(issuePremium ? 'Premium' : 'Free'));
    return true;
  }
}

class _FakePremiumRepo implements PremiumRepo {
  bool premium = false;
  bool fail = false;
  int calls = 0;

  @override
  Future<MySubscription> getMySubscription() async {
    calls++;
    if (fail) throw Exception('offline');
    return MySubscription(isPremium: premium);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
