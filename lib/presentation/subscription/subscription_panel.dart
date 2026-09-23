import 'package:auto_route/auto_route.dart';
import 'package:calora/common/di/injection.dart';
import 'package:calora/common/extensions/number_extension/number_extension.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/domain/model/premium/my_subscription.dart';
import 'package:calora/domain/model/premium/premium_plan_model.dart';
import 'package:calora/domain/repo/common/common_repo.dart';
import 'package:calora/domain/repo/premium/premium_repo.dart';
import 'package:calora/presentation/app/app/management/app_manager.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

/// Subscription info panel (bottom sheet) opened from Profile. Premium users
/// see their plan, where it came from and when it ends; free users see the
/// Premium tariffs (paid, or bought with coins) laid out as cards.
///
/// Data: `billing/subscription/my` and the Premium plans; until the status
/// loads the tier is taken from [AppManager] so the header never flickers.
class SubscriptionPanel extends StatefulWidget {
  const SubscriptionPanel({super.key});

  @override
  State<SubscriptionPanel> createState() => _SubscriptionPanelState();
}

class _SubscriptionPanelState extends State<SubscriptionPanel> {
  MySubscription? _subscription;

  @override
  void initState() {
    super.initState();
    getIt<PremiumRepo>()
        .getMySubscription()
        .then((value) {
          if (mounted) setState(() => _subscription = value);
        })
        .catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final isPremium =
        _subscription?.isPremium ??
        context.read<AppManager>().state.isUserPremium;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            'subscription_title'
                .tr()
                .text(18, 24, 600)
                .c(context.colors.textStrong),
            const SizedBox(height: 16),
            if (isPremium) ...[
              _premiumHeader(context),
              const SizedBox(height: 16),
              ..._premiumBody(context),
            ] else
              _FreeTariffs(
                onGoPremium: () => _open(context, const PremiumFeaturesRoute()),
                onOpenWallet: () => _open(context, WalletRoute()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _premiumHeader(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: RadialGradient(
          center: const Alignment(1.3, -0.8),
          radius: 1.6,
          colors: [colors.honeydew, colors.mintGreen],
          stops: const [0.0, 1.0],
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.workspace_premium_rounded,
              color: colors.textWhite,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                'current_plan'
                    .tr()
                    .text(12, 16, 500)
                    .c(colors.textWhite.withValues(alpha: 0.9)),
                const SizedBox(height: 2),
                'plan_premium'.tr().text(18, 22, 700).c(colors.textWhite),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: 'status_active'.tr().text(12, 14, 600).c(colors.textWhite),
          ),
        ],
      ),
    );
  }

  List<Widget> _premiumBody(BuildContext context) {
    final colors = context.colors;
    final sub = _subscription;
    if (sub == null) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    final endLabel = sub.autoRenew ? 'next_payment'.tr() : 'sub_ends_at'.tr();
    final endDate = sub.autoRenew ? sub.nextPaymentAt : sub.endsAt;
    return [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.strokeSoft),
        ),
        child: Column(
          children: [
            _infoRow(
              context,
              'sub_status'.tr(),
              'status_active'.tr(),
              valueColor: colors.green,
            ),
            Divider(height: 1, color: colors.strokeSoft),
            _infoRow(context, 'sub_source'.tr(), _sourceLabel(sub)),
            if (endDate != null && sub.daysLeft > 0) ...[
              Divider(height: 1, color: colors.strokeSoft),
              _infoRow(context, endLabel, _formatDate(endDate)),
              Divider(height: 1, color: colors.strokeSoft),
              _infoRow(context, 'sub_days_left'.tr(), '${sub.daysLeft}'),
            ],
          ],
        ),
      ),
      const SizedBox(height: 16),
      Button(
        text: 'change_plan'.tr(),
        type: ButtonType.secondary,
        onPressed: () => _open(context, const PremiumFeaturesRoute()),
      ),
    ];
  }

  Widget _infoRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          label.text(14, 18, 400).c(colors.textSub),
          const Spacer(),
          value.text(14, 18, 600).c(valueColor ?? colors.textStrong),
        ],
      ),
    );
  }

  /// Where the Premium came from — a paid plan, coins or invited friends.
  String _sourceLabel(MySubscription sub) {
    switch (sub.source?.toLowerCase()) {
      case 'coins':
        return 'sub_source_coins'.tr();
      case 'referral':
        return 'sub_source_referral'.tr();
      case 'admin':
        return 'sub_source_gift'.tr();
      default:
        final months = sub.durationInMonths;
        if (months == null) return 'plan_premium'.tr();
        return months == 1
            ? 'plan_monthly'.tr()
            : 'plan_n_months'.tr(namedArgs: {'count': '$months'});
    }
  }

  void _open(BuildContext context, PageRouteInfo route) {
    Navigator.of(context).pop();
    context.router.push(route);
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.'
      '${d.month.toString().padLeft(2, '0')}.${d.year}';
}

/// Free user's view: the current plan without a lone icon, the paid Premium
/// tariffs as cards (price, crossed-out original, per-month price, "popular"),
/// the coin alternative and a compact list of what Premium adds.
class _FreeTariffs extends StatefulWidget {
  const _FreeTariffs({required this.onGoPremium, required this.onOpenWallet});

  final VoidCallback onGoPremium;
  final VoidCallback onOpenWallet;

  @override
  State<_FreeTariffs> createState() => _FreeTariffsState();
}

class _FreeTariffsState extends State<_FreeTariffs> {
  List<PremiumPlanModel>? _plans;

  /// UZS prices are shown only where Payme / Click are offered; elsewhere the
  /// store sets the price (App Review 2.3.1), so the cards show none.
  bool _showPrices = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final plans = await getIt<PremiumRepo>().getPremiumPlans();
      bool uz = false;
      try {
        uz = await getIt<CommonRepo>().getIsUzbekistan().cacheAndNetwork.first;
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _plans = [...plans]
          ..sort((a, b) => (a.duration ?? 0).compareTo(b.duration ?? 0));
        _showPrices = uz;
      });
    } catch (_) {
      if (mounted) setState(() => _plans = const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final plans = _plans;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _currentPlan(context),
        const SizedBox(height: 20),
        'premium_tariffs_title'.tr().text(16, 20, 700).c(colors.textStrong),
        const SizedBox(height: 10),
        if (plans == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          for (final plan in plans) ...[
            _planCard(context, plan),
            const SizedBox(height: 10),
          ],
        _coinOption(context),
        const SizedBox(height: 18),
        _feature(context, Icons.bolt_rounded, 'premium_feat_scans'.tr()),
        _feature(context, Icons.tune_rounded, 'premium_feat_plan'.tr()),
        const SizedBox(height: 18),
        Button(text: 'go_premium'.tr(), onPressed: widget.onGoPremium),
      ],
    );
  }

  Widget _currentPlan(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.strokeSoft),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                'current_plan'.tr().text(12, 16, 500).c(colors.textSub),
                const SizedBox(height: 2),
                'plan_free'.tr().text(20, 24, 800).c(colors.textStrong),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors.backgroundElevation,
              borderRadius: BorderRadius.circular(20),
            ),
            child: 'free_plan_desc'.tr().text(12, 15, 600).c(colors.textSub),
          ),
        ],
      ),
    );
  }

  Widget _planCard(BuildContext context, PremiumPlanModel plan) {
    final colors = context.colors;
    final months = plan.duration ?? 1;
    final popular = plan.isPopular ?? false;
    final fee = plan.fee ?? 0;
    final original = (plan.originalFee ?? 0) > fee ? plan.originalFee! : null;
    final title = months == 1
        ? 'plan_monthly'.tr()
        : 'plan_n_months'.tr(namedArgs: {'count': '$months'});

    return GestureDetector(
      onTap: widget.onGoPremium,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: popular ? colors.honeydew : colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: popular ? colors.mintGreen : colors.strokeSoft,
            width: popular ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: title.text(16, 20, 700).c(colors.textStrong),
                      ),
                      if (popular) ...[
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
                  if (_showPrices && months > 1) ...[
                    const SizedBox(height: 3),
                    'price_per_month'
                        .tr(namedArgs: {'price': (fee ~/ months).formatPrice()})
                        .text(12, 15, 500)
                        .c(colors.textSub),
                  ],
                ],
              ),
            ),
            if (_showPrices)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  '${fee.formatPrice()} UZS'
                      .text(16, 20, 800)
                      .c(colors.textStrong),
                  if (original != null)
                    Text(
                      '${original.formatPrice()} UZS',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSub,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                ],
              )
            else
              Icon(Icons.chevron_right_rounded, color: colors.iconSoft),
          ],
        ),
      ),
    );
  }

  /// Premium can also be bought with coins earned by walking.
  Widget _coinOption(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: widget.onOpenWallet,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.backgroundElevation,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.monetization_on_rounded,
                color: colors.accentSub,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  'premium_with_coins'
                      .tr()
                      .text(14, 18, 700)
                      .c(colors.textStrong),
                  const SizedBox(height: 2),
                  'premium_with_coins_sub'
                      .tr()
                      .text(12, 16, 400)
                      .c(colors.textSub),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.iconSoft),
          ],
        ),
      ),
    );
  }

  Widget _feature(BuildContext context, IconData icon, String text) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              color: colors.lightGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: colors.accentSub),
          ),
          const SizedBox(width: 12),
          Expanded(child: text.text(14, 18, 500).c(colors.textStrong)),
          Icon(Icons.check_rounded, size: 18, color: colors.accentSub),
        ],
      ),
    );
  }
}
