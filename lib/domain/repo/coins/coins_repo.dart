import 'package:calora/domain/model/coins/coin_transaction.dart';
import 'package:calora/domain/model/coins/market_item.dart';
import 'package:calora/domain/model/coins/wallet.dart';
import 'package:calora/domain/model/user/user_stat.dart';

abstract class CoinsRepo {
  Future<Wallet> getWallet();

  Future<List<CoinTransaction>> getTransactions();

  /// Returns the minted coin count and the fresh wallet.
  Future<(int, Wallet)> exchange(int calora);

  Future<List<MarketItem>> getMarket();

  Future<MarketPurchaseResult> purchase(MarketItem item);

  Future<List<UserStatRequest>> getRanking();
}
