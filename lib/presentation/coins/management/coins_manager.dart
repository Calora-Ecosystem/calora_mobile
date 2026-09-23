import 'dart:async';

import 'package:calora/common/di/network/interceptor/token_interceptor.dart';
import 'package:calora/common/extensions/api_error_extension.dart';
import 'package:calora/domain/model/coins/market_item.dart';
import 'package:calora/domain/repo/coins/coins_repo.dart';
import 'package:calora/presentation/coins/management/coins_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

/// Drives the wallet and the marketplace against the `wallet` API. Coins are
/// earned on the server from the user's steps (1000 steps = 1 coin), so the
/// app only reads the balance and spends it. Each page gets its own manager;
/// they stay in sync because every screen re-reads the server ([refresh]).
@injectable
class CoinsManager extends Manager<CoinsState, CoinsEffect> {
  final CoinsRepo _repo;
  final TokenInterceptor _tokenInterceptor;

  CoinsManager(this._repo, this._tokenInterceptor) : super(const CoinsState());

  @override
  void initialize() {
    refresh();
  }

  /// Re-reads wallet, history and catalog — used on open and when returning
  /// to a screen after the balance may have changed on another.
  Future<void> refresh() async {
    try {
      final walletFuture = _repo.getWallet();
      final transactionsFuture = _repo.getTransactions();
      final catalogFuture = _repo.getMarket();
      final wallet = await walletFuture;
      final transactions = await transactionsFuture;
      final catalog = await catalogFuture;
      if (isClosed) return;
      emit(
        state.copyWith(
          loading: false,
          balance: wallet.balance,
          todayCoins: wallet.todayCoins,
          stepsPerCoin: wallet.stepsPerCoin,
          maxDailyCoins: wallet.maxDailyCoins,
          transactions: transactions,
          catalog: catalog,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(loading: false));
      publish(const CoinsEffect.failed());
    }
  }

  /// Spends coins on a marketplace item. Premium rewards live in the JWT, so
  /// the token is refreshed right away to unlock Premium in the app.
  Future<void> purchase(MarketItem item) async {
    if (state.busy) return;
    if (state.balance < item.priceCoins) {
      publish(const CoinsEffect.insufficientCoins());
      return;
    }
    emit(state.copyWith(busy: true));
    try {
      final result = await _repo.purchase(item);
      if (result.requiresTokenRefresh) {
        await _tokenInterceptor.refreshAndCheckPremium();
      }
      if (isClosed) return;
      emit(state.copyWith(busy: false));
      publish(CoinsEffect.purchased(item, result.code));
      unawaited(refresh());
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(busy: false));
      publish(
        e.apiErrorCode == 'insufficient_coins'
            ? const CoinsEffect.insufficientCoins()
            : const CoinsEffect.failed(),
      );
    }
  }
}
