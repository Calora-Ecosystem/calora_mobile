/// Section a marketplace item belongs to. Drives both the category filter and
/// the leading glyph on the card.
enum MarketCategory { tariff, voucher, boost }

/// What the user receives for a purchase — mirrors the backend
/// `EnumMarketRewardType`.
enum MarketRewardType { premiumDays, aiScans, coupon, voucher }

/// A purchasable item in the coin marketplace (`GET wallet/market`). [title]
/// and [subtitle] are localization keys resolved where the item is rendered.
class MarketItem {
  final int id;
  final String title;
  final String subtitle;
  final int priceCoins;
  final MarketCategory category;
  final MarketRewardType rewardType;
  final int rewardValue;
  final bool isPopular;

  const MarketItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.priceCoins,
    required this.category,
    this.rewardType = MarketRewardType.voucher,
    this.rewardValue = 0,
    this.isPopular = false,
  });

  factory MarketItem.fromJson(Map<String, dynamic> json) => MarketItem(
    id: (json['id'] as num?)?.toInt() ?? 0,
    title: json['title'] as String? ?? '',
    subtitle: json['subtitle'] as String? ?? '',
    priceCoins: (json['priceCoins'] as num?)?.toInt() ?? 0,
    category: switch ((json['category'] as String?)?.toLowerCase()) {
      'voucher' => MarketCategory.voucher,
      'boost' => MarketCategory.boost,
      _ => MarketCategory.tariff,
    },
    rewardType: switch ((json['rewardType'] as String?)?.toLowerCase()) {
      'premiumdays' => MarketRewardType.premiumDays,
      'aiscans' => MarketRewardType.aiScans,
      'coupon' => MarketRewardType.coupon,
      _ => MarketRewardType.voucher,
    },
    rewardValue: (json['rewardValue'] as num?)?.toInt() ?? 0,
    isPopular: json['isPopular'] as bool? ?? false,
  );
}

/// Result of `POST wallet/market/{id}/purchase`.
class MarketPurchaseResult {
  final MarketItem item;

  /// Coupon / voucher code, when the reward is one.
  final String? code;

  /// Premium was granted — the plan lives in the JWT, so the app must refresh
  /// its token to see it.
  final bool requiresTokenRefresh;

  const MarketPurchaseResult({
    required this.item,
    this.code,
    this.requiresTokenRefresh = false,
  });
}
