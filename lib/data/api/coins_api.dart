import 'package:calora/common/base/profile_store.dart';
import 'package:calora/domain/model/coins/coin_transaction.dart';
import 'package:calora/domain/model/coins/market_item.dart';
import 'package:calora/domain/model/coins/wallet.dart';
import 'package:calora/domain/model/user/user_stat.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class CoinsApi {
  final Dio _dio;

  CoinsApi(this._dio);

  Future<Wallet> getWallet() async {
    final response = await _dio.get<Map<String, dynamic>>('wallet');
    return Wallet.fromJson(response.data!['content'] as Map<String, dynamic>);
  }

  Future<List<CoinTransaction>> getTransactions({
    int skip = 0,
    int take = 50,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      'wallet/transactions',
      queryParameters: {'Skip': skip, 'Take': take},
    );
    final content = response.data!['content'] as List<dynamic>? ?? [];
    return content
        .whereType<Map<String, dynamic>>()
        .map(CoinTransaction.fromJson)
        .toList();
  }

  Future<List<MarketItem>> getMarket() async {
    final response = await _dio.get<Map<String, dynamic>>(
      'wallet/market',
      queryParameters: {'Skip': 0, 'Take': 100},
    );
    final content = response.data!['content'] as List<dynamic>? ?? [];
    return content
        .whereType<Map<String, dynamic>>()
        .map(MarketItem.fromJson)
        .toList();
  }

  Future<MarketPurchaseResult> purchase(MarketItem item) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'wallet/market/${item.id}/purchase',
    );
    final content = response.data!['content'] as Map<String, dynamic>;
    final purchase = content['purchase'] as Map<String, dynamic>? ?? {};
    return MarketPurchaseResult(
      item: item,
      code: purchase['code'] as String?,
      requiresTokenRefresh: content['requiresTokenRefresh'] as bool? ?? false,
    );
  }

  /// Public coin leaderboard. Mapped onto [UserStatRequest] so the step
  /// ranking widgets render it unchanged — `stepCount` carries the coins.
  Future<List<UserStatRequest>> getRanking({int take = 50}) async {
    final currentUserId = await profileStore.getUserId() ?? 0;
    final response = await _dio.get<Map<String, dynamic>>(
      'wallet/ranking',
      queryParameters: {'Skip': 0, 'Take': take},
    );
    final content = response.data!['content'] as List<dynamic>? ?? [];
    return content.whereType<Map<String, dynamic>>().map((json) {
      final user = json['user'] as Map<String, dynamic>? ?? {};
      return UserStatRequest(
        firstName: user['name'] as String? ?? '',
        lastName: '',
        stepCount: (json['sum'] as num?)?.toInt() ?? 0,
        talks: 0,
        isMe: user['id'] == currentUserId,
        isWinner: json['index'] == 1,
      );
    }).toList();
  }
}
