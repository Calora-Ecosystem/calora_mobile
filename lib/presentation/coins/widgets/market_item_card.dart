import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/domain/model/coins/market_item.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// One Premium tariff in the coin shop: how many days, a short tagline, the
/// coin price per day and the price itself. The popular tariff is outlined in
/// mint with a badge; a tariff the user can't afford yet shows how many coins
/// are missing instead of looking tappable.
class MarketItemCard extends StatelessWidget {
  const MarketItemCard({
    super.key,
    required this.item,
    required this.balance,
    required this.onBuy,
  });

  final MarketItem item;
  final int balance;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final days = item.rewardValue;
    final affordable = balance >= item.priceCoins;
    final perDay = days > 0 ? (item.priceCoins / days) : 0;

    return GestureDetector(
      onTap: onBuy,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
        decoration: BoxDecoration(
          color: item.isPopular ? colors.honeydew : colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: item.isPopular ? colors.mintGreen : colors.strokeSoft,
            width: item.isPopular ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(0.6, -0.6),
                  radius: 1.2,
                  colors: [colors.honeydew, colors.mintGreen],
                ),
              ),
              child: Icon(
                Icons.workspace_premium_rounded,
                color: colors.textWhite,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: 'tariff_days'
                            .tr(namedArgs: {'count': '$days'})
                            .text(18, 22, 700)
                            .c(colors.textStrong),
                      ),
                      if (item.isPopular) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colors.mintGreen,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: 'popular'
                              .tr()
                              .text(10, 12, 700)
                              .c(colors.textWhite),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  item.subtitle.tr().text(13, 17, 500).c(colors.textSub),
                  const SizedBox(height: 3),
                  (affordable
                          ? 'tariff_per_day'.tr(
                              namedArgs: {'coins': perDay.toStringAsFixed(1)},
                            )
                          : 'tariff_missing'.tr(
                              namedArgs: {
                                'coins': '${item.priceCoins - balance}',
                              },
                            ))
                      .text(12, 15, 500)
                      .c(affordable ? colors.accentSub : colors.errorBase),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: affordable
                    ? colors.accentSub
                    : colors.accentSub.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.monetization_on_rounded,
                    size: 16,
                    color: colors.textWhite,
                  ),
                  const SizedBox(width: 4),
                  '${item.priceCoins}'.text(15, 18, 700).c(colors.textWhite),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
