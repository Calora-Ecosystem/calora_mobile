import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/domain/model/coins/market_item.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// A single marketplace tile: category glyph, title/subtitle and a coin-priced
/// buy action. "Popular" items get a small accent badge.
class MarketItemCard extends StatelessWidget {
  const MarketItemCard({super.key, required this.item, required this.onBuy});

  final MarketItem item;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.strokeSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: colors.lightGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_icon(), size: 22, color: colors.accentSub),
              ),
              const Spacer(),
              if (item.isPopular)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.lightGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: 'popular'.tr().text(10, 12, 600).c(colors.accentSub),
                ),
            ],
          ),
          const SizedBox(height: 12),
          item.title.tr().text(14, 18, 600).c(colors.textStrong),
          const SizedBox(height: 2),
          item.subtitle.tr().text(12, 15, 400).c(colors.textSub),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onBuy,
            child: Container(
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.accentSub,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.monetization_on_rounded,
                    size: 15,
                    color: colors.textWhite,
                  ),
                  const SizedBox(width: 5),
                  '${item.priceCoins}'.text(13, 16, 600).c(colors.textWhite),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _icon() {
    switch (item.category) {
      case MarketCategory.tariff:
        return Icons.workspace_premium_rounded;
      case MarketCategory.voucher:
        return Icons.local_offer_rounded;
      case MarketCategory.boost:
        return Icons.bolt_rounded;
    }
  }
}
