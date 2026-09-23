import 'package:calora/domain/model/coins/coin_transaction.dart';
import 'package:calora/domain/model/coins/market_item.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'coins_management.freezed.dart';

@freezed
abstract class CoinsState with _$CoinsState {
  const factory CoinsState({
    @Default(true) bool loading,
    @Default(false) bool busy,
    @Default(0) int balance,
    @Default(0) int todayCoins,
    @Default(1000) int stepsPerCoin,
    @Default(22) int maxDailyCoins,
    @Default([]) List<CoinTransaction> transactions,
    @Default([]) List<MarketItem> catalog,
  }) = _CoinsState;
}

@freezed
class CoinsEffect with _$CoinsEffect {
  const factory CoinsEffect.purchased(MarketItem item, String? code) =
      Purchased;

  const factory CoinsEffect.insufficientCoins() = InsufficientCoins;

  const factory CoinsEffect.failed() = CoinsFailed;
}
