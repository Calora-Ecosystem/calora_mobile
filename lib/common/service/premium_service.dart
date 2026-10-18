import 'dart:async';

import 'package:calora/common/di/network/interceptor/token_interceptor.dart';
import 'package:calora/common/enums/subscription_plan_type.dart';
import 'package:calora/data/store/auth/auth_store.dart';
import 'package:calora/data/store/common/common_store.dart';
import 'package:calora/domain/model/token/token.dart';
import 'package:calora/domain/repo/premium/premium_repo.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

@lazySingleton
class PremiumService {
  PremiumService(this._commonStore, this._authStore, this._tokens, this._repo);

  final CommonStore _commonStore;
  final AuthStore _authStore;
  final TokenInterceptor _tokens;
  final PremiumRepo _repo;

  static const syncInterval = Duration(seconds: 30);
  static const confirmWindow = Duration(minutes: 3);

  @visibleForTesting
  DateTime Function() now = DateTime.now;

  @visibleForTesting
  Duration confirmInterval = const Duration(seconds: 5);

  StreamSubscription<Token?>? _tokenSubscription;
  AppLifecycleListener? _lifecycleListener;
  Future<bool>? _inFlight;
  DateTime? _syncedAt;
  bool? _serverPremium;
  DateTime? _optimisticUntil;
  Timer? _confirmTimer;

  static bool isPremiumToken(String? accessToken) {
    if (accessToken == null || accessToken.isEmpty) return false;
    try {
      final plan = JwtDecoder.decode(accessToken)['plan'];
      return plan is String && !SubscriptionPlanType.fromApi(plan).isFree;
    } catch (_) {
      return false;
    }
  }

  bool get _isOptimistic {
    final until = _optimisticUntil;
    return until != null && now().isBefore(until);
  }

  void start() {
    _tokenSubscription ??= _authStore.token.watch().skip(1).listen(_onToken);
    _lifecycleListener ??= AppLifecycleListener(
      onResume: () => unawaited(sync()),
    );
    unawaited(sync());
  }

  Future<bool> sync({bool force = false}) {
    final syncedAt = _syncedAt;
    if (!force &&
        syncedAt != null &&
        now().difference(syncedAt) < syncInterval) {
      return _commonStore.isUserPremium();
    }
    return _inFlight ??= _sync().whenComplete(() => _inFlight = null);
  }

  Future<void> markPurchased() async {
    _optimisticUntil = now().add(confirmWindow);
    _serverPremium = null;
    await _apply(true);
    _confirmTimer?.cancel();
    _confirmTimer = Timer.periodic(
      confirmInterval,
      (_) => unawaited(_confirm()),
    );
    unawaited(_confirm());
  }

  @visibleForTesting
  void dispose() {
    _tokenSubscription?.cancel();
    _tokenSubscription = null;
    _lifecycleListener?.dispose();
    _lifecycleListener = null;
    _endOptimism();
  }

  Future<bool> _sync() async {
    try {
      if (!await _signedIn()) return false;
      final premium = (await _repo.getMySubscription()).isPremium;
      if (!await _signedIn()) return false;

      _serverPremium = premium;
      _syncedAt = now();
      if (premium) _endOptimism();
      await _apply(premium);

      final token = await _authStore.token();
      if (isPremiumToken(token?.accessToken) != premium) {
        await _tokens.refreshTokens();
      }
      return premium || _isOptimistic;
    } catch (_) {
      return _commonStore.isUserPremium();
    }
  }

  Future<void> _confirm() async {
    await sync(force: true);
    if (_serverPremium == true || _isOptimistic) return;
    _endOptimism();
    if (_serverPremium case final server?) await _apply(server);
  }

  Future<void> _onToken(Token? token) async {
    final accessToken = token?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      _serverPremium = null;
      _syncedAt = null;
      _endOptimism();
      await _apply(false);
      return;
    }

    final claim = isPremiumToken(accessToken);
    final server = _serverPremium;
    if (server == null || server == claim) await _apply(claim);
    if (server != claim) unawaited(sync());
  }

  Future<bool> _signedIn() async =>
      (await _authStore.token())?.accessToken?.isNotEmpty ?? false;

  void _endOptimism() {
    _optimisticUntil = null;
    _confirmTimer?.cancel();
    _confirmTimer = null;
  }

  Future<void> _apply(bool premium) async {
    final value = premium || _isOptimistic;
    if (await _commonStore.isUserPremium() == value) return;
    await _commonStore.isUserPremium.set(value);
  }
}
