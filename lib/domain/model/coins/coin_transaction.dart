/// Whether a coin movement added to or spent from the wallet.
enum CoinTxType { earn, spend }

/// A single line in the wallet history (`GET wallet/transactions`). [title] is
/// a localization key resolved in the tile, [amount] is signed (positive =
/// earned, negative = spent) so the history reads without extra branching.
class CoinTransaction {
  final int id;
  final String title;
  final int amount;
  final CoinTxType type;
  final DateTime date;

  const CoinTransaction({
    this.id = 0,
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
  });

  factory CoinTransaction.fromJson(Map<String, dynamic> json) {
    final amount = (json['amount'] as num?)?.toInt() ?? 0;
    return CoinTransaction(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      amount: amount,
      type: amount >= 0 ? CoinTxType.earn : CoinTxType.spend,
      date:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
