import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/domain/model/coins/market_item.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// A single tariff tile in the coin shop grid: Premium glyph, title/subtitle
/// and a coin-priced buy action.
class MarketItemCard extends StatelessWidget {
  const MarketItemCard({super.key, required this.item, required this.onBuy});

  final MarketItem item;
  final VoidCallback onBuy;

  /// Tariffs are created on the admin dashboard with a `mi_premium_<days>` key;
  /// durations the app has no string for fall back to a generic "Premium N days".
  String _title() {
    if (item.title.trExists()) return item.title.tr();
    if (item.rewardType == MarketRewardType.premiumDays && item.rewardValue > 0) {
      return 'mi_premium_days'.tr(namedArgs: {'days': '${item.rewardValue}'});
    }
    return item.title;
  }

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
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: colors.lightGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.workspace_premium_rounded,
              size: 22,
              color: colors.accentSub,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _title(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              height: 18 / 14,
              fontWeight: FontWeight.w600,
              color: colors.textStrong,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.subtitle.tr(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              height: 15 / 12,
              color: colors.textSub,
            ),
          ),
          const Spacer(),
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
}
