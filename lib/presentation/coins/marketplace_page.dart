import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/snack_bar/custom_snack_bar.dart';
import 'package:calora/domain/model/coins/market_item.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/coins/management/coins_management.dart';
import 'package:calora/presentation/coins/management/coins_manager.dart';
import 'package:calora/presentation/coins/widgets/market_item_card.dart';
import 'package:calora/widgets/app_bar/custom_app_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

/// Coin shop — Premium tariffs only (7 / 30 / 75 / 120 days). Buying one turns
/// Premium on right away (or extends an active Premium) until the chosen date.
@RoutePage()
class MarketplacePage extends Managed<CoinsManager, CoinsState, CoinsEffect> {
  MarketplacePage({super.key});

  @override
  void listener(
    BuildContext context,
    CoinsManager manager,
    CoinsEffect effect,
  ) {
    effect.mapOrNull(
      purchased: (e) => _showSuccess(context, e.item),
      insufficientCoins: (_) =>
          CustomSnackBar.show(context, 'insufficient_coins'.tr()),
      failed: (_) => CustomSnackBar.show(context, 'something_went_wrong'.tr()),
    );
  }

  @override
  Widget builder(BuildContext context, CoinsManager manager, CoinsState state) {
    final colors = context.colors;
    final tariffs =
        state.catalog
            .where(
              (i) =>
                  i.category == MarketCategory.tariff &&
                  i.rewardType == MarketRewardType.premiumDays,
            )
            .toList()
          ..sort((a, b) => a.rewardValue.compareTo(b.rewardValue));

    return Scaffold(
      backgroundColor: colors.softGray,
      appBar: CustomAppBar(
        title: 'marketplace_title'.tr(),
        onBack: () => context.router.maybePop(),
        trailing: _balanceChip(context, state.balance),
      ),
      body: state.loading && tariffs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: manager.refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  'market_tariffs_title'
                      .tr()
                      .text(20, 26, 700)
                      .c(colors.textStrong),
                  const SizedBox(height: 4),
                  'market_tariffs_sub'.tr().text(14, 19, 400).c(colors.textSub),
                  const SizedBox(height: 16),
                  for (final item in tariffs) ...[
                    MarketItemCard(
                      item: item,
                      balance: state.balance,
                      onBuy: () {
                        if (!state.busy)
                          _confirm(context, manager, state, item);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
    );
  }

  /// Coins can't be refunded, so a purchase is confirmed first; a tariff the
  /// user can't afford explains how many coins are missing instead.
  void _confirm(
    BuildContext context,
    CoinsManager manager,
    CoinsState state,
    MarketItem item,
  ) {
    if (state.balance < item.priceCoins) {
      CustomSnackBar.show(
        context,
        'tariff_missing'.tr(
          namedArgs: {'coins': '${item.priceCoins - state.balance}'},
        ),
      );
      return;
    }
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: 'tariff_confirm_title'
            .tr()
            .text(18, 24, 700)
            .c(colors.textStrong),
        content: 'tariff_confirm_msg'
            .tr(
              namedArgs: {
                'coins': '${item.priceCoins}',
                'days': '${item.rewardValue}',
              },
            )
            .text(14, 20, 400)
            .c(colors.textSub),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Strings.close.text(14, 18, 500).c(colors.textSub),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              manager.purchase(item);
            },
            child: 'buy'.tr().text(14, 18, 700).c(colors.accentSub),
          ),
        ],
      ),
    );
  }

  void _showSuccess(BuildContext context, MarketItem item) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              height: 64,
              width: 64,
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
                size: 34,
              ),
            ),
            const SizedBox(height: 14),
            'tariff_success_title'
                .tr()
                .text(18, 24, 700)
                .c(colors.textStrong)
                .copyWith(textAlign: TextAlign.center),
            const SizedBox(height: 6),
            'tariff_success_msg'
                .tr(namedArgs: {'days': '${item.rewardValue}'})
                .text(14, 20, 400)
                .c(colors.textSub)
                .copyWith(textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: 'great'.tr().text(15, 20, 700).c(colors.accentSub),
          ),
        ],
      ),
    );
  }

  Widget _balanceChip(BuildContext context, int balance) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.lightGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.monetization_on_rounded,
            size: 15,
            color: colors.accentSub,
          ),
          const SizedBox(width: 4),
          '$balance'.text(13, 16, 600).c(colors.accentSub),
        ],
      ),
    );
  }
}
