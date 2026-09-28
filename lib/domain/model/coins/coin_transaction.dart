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

  /// When the coins were written to the wallet. Step coins for several days
  /// can land at once (e.g. the first sync after install), so for them
  /// [stepDate] is the day that matters.
  final DateTime date;

  /// Step coins only: the day whose steps earned them.
  final DateTime? stepDate;

  /// Step coins only: that day's step count.
  final int? steps;

  const CoinTransaction({
    this.id = 0,
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
    this.stepDate,
    this.steps,
  });

  /// The date shown in the history — the step day for step coins.
  DateTime get displayDate => stepDate ?? date;

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
      stepDate: DateTime.tryParse(json['stepDate'] as String? ?? ''),
      steps: (json['steps'] as num?)?.toInt(),
    );
  }
}
