/// Coin wallet snapshot (`GET wallet`). Coins are earned only by walking:
/// every [stepsPerCoin] steps give one coin, at most [maxDailyCoins] a day.
class Wallet {
  final int balance;

  /// Coins credited for today's steps so far.
  final int todayCoins;

  /// How many steps make one coin (server-controlled, 1000 by default).
  final int stepsPerCoin;

  /// Daily ceiling for step coins (server-controlled, 22 by default).
  final int maxDailyCoins;

  const Wallet({
    this.balance = 0,
    this.todayCoins = 0,
    this.stepsPerCoin = 1000,
    this.maxDailyCoins = 22,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
    balance: (json['balance'] as num?)?.toInt() ?? 0,
    todayCoins: (json['todayCoins'] as num?)?.toInt() ?? 0,
    stepsPerCoin: (json['stepsPerCoin'] as num?)?.toInt() ?? 1000,
    maxDailyCoins: (json['maxDailyCoins'] as num?)?.toInt() ?? 22,
  );
}
