import 'package:calora/domain/model/coins/coin_transaction.dart';
import 'package:calora/domain/model/coins/market_item.dart';
import 'package:calora/domain/model/coins/wallet.dart';
import 'package:calora/domain/model/user/user_stat.dart';

abstract class CoinsRepo {
  Stream<Wallet> get walletChanges;

  Future<Wallet> getWallet();

  Future<List<CoinTransaction>> getTransactions();

  Future<List<MarketItem>> getMarket();

  Future<MarketPurchaseResult> purchase(MarketItem item);

  Future<List<UserStatRequest>> getRanking();
}
