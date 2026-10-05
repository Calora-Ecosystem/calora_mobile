import 'dart:math';

const int kFreeAiScanLimit = 5;

class AiQuota {
  final bool isPremium;
  final bool unlimited;
  final int limit;
  final int used;
  final int remaining;

  const AiQuota({
    this.isPremium = false,
    this.unlimited = false,
    this.limit = kFreeAiScanLimit,
    this.used = 0,
    this.remaining = kFreeAiScanLimit,
  });

  static const premium = AiQuota(isPremium: true, unlimited: true);

  bool get isUnlimited => isPremium || unlimited;

  bool get canUse => isUnlimited || remaining > 0;

  int get shownRemaining => remaining.clamp(0, max(0, limit));

  factory AiQuota.fromJson(Map<String, dynamic> json) => AiQuota(
    isPremium: json['isPremium'] as bool? ?? false,
    unlimited: json['unlimited'] as bool? ?? false,
    limit: (json['limit'] as num?)?.toInt() ?? kFreeAiScanLimit,
    used: (json['used'] as num?)?.toInt() ?? 0,
    remaining: (json['remaining'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'isPremium': isPremium,
    'unlimited': unlimited,
    'limit': limit,
    'used': used,
    'remaining': remaining,
  };
}
