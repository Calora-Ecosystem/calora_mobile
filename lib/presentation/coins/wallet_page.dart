import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/domain/model/coins/coin_transaction.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/coins/management/coins_management.dart';
import 'package:calora/presentation/coins/management/coins_manager.dart';
import 'package:calora/presentation/coins/widgets/coin_balance_card.dart';
import 'package:calora/widgets/app_bar/custom_app_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

/// Coins are earned only by walking (server credits them from the synced
/// steps) and spent in the marketplace — there is no exchange step.
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
      body: RefreshIndicator(
        onRefresh: manager.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            CoinBalanceCard(
              coinBalance: state.balance,
              todayCoins: state.todayCoins,
            ),
            const SizedBox(height: 14),
            _EarnRuleCard(
              stepsPerCoin: state.stepsPerCoin,
              maxDailyCoins: state.maxDailyCoins,
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
            const SizedBox(height: 20),
            'recent_activity'
                .tr()
                .text(16, 20, 600)
                .c(context.colors.textStrong),
            const SizedBox(height: 10),
            if (state.loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.transactions.isEmpty)
              'wallet_no_activity'
                  .tr()
                  .text(13, 18, 400)
                  .c(context.colors.textSub)
            else
              _HistoryCard(transactions: state.transactions),
          ],
        ),
      ),
    );
  }
}

/// How coins are earned: every N steps is a coin, up to a daily limit.
class _EarnRuleCard extends StatelessWidget {
  const _EarnRuleCard({
    required this.stepsPerCoin,
    required this.maxDailyCoins,
  });

  final int stepsPerCoin;
  final int maxDailyCoins;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.honeydew,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.paleGreen),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.directions_walk_rounded,
              color: colors.accentSub,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                'coin_earn_rule'
                    .tr(namedArgs: {'steps': '$stepsPerCoin'})
                    .text(15, 20, 600)
                    .c(colors.textStrong),
                const SizedBox(height: 3),
                'coin_earn_limit'
                    .tr(namedArgs: {'coins': '$maxDailyCoins'})
                    .text(13, 17, 400)
                    .c(colors.textSub),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Wallet history: daily step coins in, marketplace purchases out.
class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.transactions});

  final List<CoinTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          for (int i = 0; i < transactions.length; i++) ...[
            if (i > 0) Divider(height: 1, color: colors.strokeSoft),
            _row(context, transactions[i]),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, CoinTransaction tx) {
    final colors = context.colors;
    final earn = tx.type == CoinTxType.earn;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: earn ? colors.lightGreen : colors.backgroundElevation,
              shape: BoxShape.circle,
            ),
            child: Icon(
              earn ? Icons.directions_walk_rounded : Icons.shopping_bag_rounded,
              size: 18,
              color: earn ? colors.accentSub : colors.textSub,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                tx.title.tr().text(14, 18, 600).c(colors.textStrong),
                const SizedBox(height: 2),
                _formatDate(tx.date).text(12, 15, 400).c(colors.textSub),
              ],
            ),
          ),
          '${earn ? '+' : ''}${tx.amount}'
              .text(15, 18, 700)
              .c(earn ? colors.accentSub : colors.textStrong),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.'
      '${d.month.toString().padLeft(2, '0')}.${d.year}';
}

/// Full-width white action card echoing the balance card's shape (rounded 20,
/// soft lift) so the wallet reads as cards of one family.
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
