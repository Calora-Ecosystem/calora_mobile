/// Coin wallet snapshot (`GET wallet`).
class Wallet {
  final int balance;

  /// Calora (kcal burned by steps) that can still be exchanged for coins.
  final int availableCalora;

  /// How many Calora make one coin (server-controlled, 1000 by default).
  final int caloraPerCoin;

  /// Coins the current [availableCalora] can mint right now.
  final int maxExchangeableCoins;

  const Wallet({
    this.balance = 0,
    this.availableCalora = 0,
    this.caloraPerCoin = 1000,
    this.maxExchangeableCoins = 0,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
    balance: (json['balance'] as num?)?.toInt() ?? 0,
    availableCalora: (json['availableCalora'] as num?)?.toInt() ?? 0,
    caloraPerCoin: (json['caloraPerCoin'] as num?)?.toInt() ?? 1000,
    maxExchangeableCoins: (json['maxExchangeableCoins'] as num?)?.toInt() ?? 0,
  );
}
