import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The wallet's hero card: the coin balance next to the coins earned from
/// today's steps, on the app's signature mint gradient.
class CoinBalanceCard extends StatelessWidget {
  const CoinBalanceCard({
    super.key,
    required this.coinBalance,
    required this.todayCoins,
  });

  final int coinBalance;

  /// Coins credited for today's steps so far.
  final int todayCoins;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: RadialGradient(
          center: const Alignment(1.3, -0.9),
          radius: 1.5,
          colors: [colors.honeydew, colors.mintGreen],
          stops: const [0.0, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.mintGreen.withValues(alpha: 0.30),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              'total_balance'
                  .tr()
                  .text(13, 16, 500)
                  .c(colors.textWhite.withValues(alpha: 0.9)),
              const Spacer(),
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: colors.textWhite,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _statTile(
                  context,
                  icon: Icon(
                    Icons.monetization_on_rounded,
                    color: colors.textWhite,
                    size: 20,
                  ),
                  value: coinBalance,
                  label: 'coin_unit'.tr(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statTile(
                  context,
                  icon: Icon(
                    Icons.directions_walk_rounded,
                    color: colors.textWhite,
                    size: 20,
                  ),
                  value: todayCoins,
                  label: 'wallet_today_coins'.tr(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// A translucent tile inside the hero — the icon + label name the currency
  /// and the big number reads as the amount, clearly separated from its twin.
  Widget _statTile(
    BuildContext context, {
    required Widget icon,
    required int value,
    required String label,
  }) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              icon,
              const SizedBox(width: 6),
              label
                  .text(13, 16, 500)
                  .c(colors.textWhite.withValues(alpha: 0.9)),
            ],
          ),
          const SizedBox(height: 8),
          '$value'.text(24, 28, 700).c(colors.textWhite),
        ],
      ),
    );
  }
}
