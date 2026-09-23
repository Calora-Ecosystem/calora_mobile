import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/coins/management/coins_management.dart';
import 'package:calora/presentation/coins/management/coins_manager.dart';
import 'package:calora/presentation/coins/widgets/coin_balance_card.dart';
import 'package:calora/widgets/app_bar/custom_app_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

@RoutePage()
class WalletPage extends Managed<CoinsManager, CoinsState, CoinsEffect> {
  WalletPage({super.key});

  @override
  void onNavigateBack(CoinsManager manager) => manager.refresh();

  @override
  Widget builder(BuildContext context, CoinsManager manager, CoinsState state) {
    return Scaffold(
      backgroundColor: context.colors.softGray,
      appBar: CustomAppBar(
        title: 'wallet_title'.tr(),
        onBack: () => context.router.maybePop(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          CoinBalanceCard(
            coinBalance: state.balance,
            caloraBalance: state.availableCalora,
          ),
          const SizedBox(height: 14),
          _ActionCard(
            icon: Icons.swap_horiz_rounded,
            title: 'exchange_to_coins'.tr(),
            subtitle: 'Calora → Coin',
            onTap: () async {
              await context.router.push(ExchangeRoute());
              manager.refresh();
            },
          ),
          const SizedBox(height: 14),
          _ActionCard(
            icon: Icons.storefront_rounded,
            title: 'marketplace_title'.tr(),
            subtitle: 'market_subtitle'.tr(),
            onTap: () async {
              await context.router.push(MarketplaceRoute());
              manager.refresh();
            },
          ),
        ],
      ),
    );
  }
}

/// Full-width white action card echoing the balance card's shape (rounded 20,
/// soft lift) so the wallet reads as three cards of one family.
class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: colors.lightGreen,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: colors.accentSub, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title.text(16, 20, 600).c(colors.textStrong),
                  const SizedBox(height: 3),
                  subtitle.text(13, 16, 400).c(colors.textSub),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.iconSoft),
          ],
        ),
      ),
    );
  }
}
