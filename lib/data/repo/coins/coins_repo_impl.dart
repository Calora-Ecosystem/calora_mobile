import 'package:calora/data/api/coins_api.dart';
import 'package:calora/domain/model/coins/coin_transaction.dart';
import 'package:calora/domain/model/coins/market_item.dart';
import 'package:calora/domain/model/coins/wallet.dart';
import 'package:calora/domain/model/user/user_stat.dart';
import 'package:calora/domain/repo/coins/coins_repo.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: CoinsRepo)
class CoinsRepoImpl implements CoinsRepo {
  final CoinsApi _api;

  CoinsRepoImpl(this._api);

  @override
  Future<Wallet> getWallet() => _api.getWallet();

  @override
  Future<List<CoinTransaction>> getTransactions() => _api.getTransactions();

  @override
  Future<List<MarketItem>> getMarket() => _api.getMarket();

  @override
  Future<MarketPurchaseResult> purchase(MarketItem item) => _api.purchase(item);

  @override
  Future<List<UserStatRequest>> getRanking() => _api.getRanking();
}
