import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:calora/common/di/injection.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/domain/model/premium/my_subscription.dart';
import 'package:calora/domain/repo/premium/premium_repo.dart';
import 'package:calora/presentation/app/app/management/app_manager.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';
import 'package:url_launcher/url_launcher.dart';

/// Profile → Subscription (bottom sheet). A plain, at-a-glance view of the
/// user's plan so billing never surprises them (and store rules are met):
///
/// 1. current plan — Free or Premium,
/// 2. next payment date,
/// 3. status — active or cancelled,
///
/// plus "change plan" for Premium and "Go Premium" for Free.
/// Data: `billing/subscription/my`; until it loads the tier comes from
/// [AppManager] so the header never flickers.
class SubscriptionPanel extends StatefulWidget {
  const SubscriptionPanel({super.key});

  @override
  State<SubscriptionPanel> createState() => _SubscriptionPanelState();
}

class _SubscriptionPanelState extends State<SubscriptionPanel> {
  MySubscription? _sub;

  @override
  void initState() {
    super.initState();
    getIt<PremiumRepo>()
        .getMySubscription()
        .then((value) {
          if (mounted) setState(() => _sub = value);
        })
        .catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sub = _sub;
    final isPremium =
        sub?.isPremium ?? context.read<AppManager>().state.isUserPremium;

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
            'subscription_title'.tr().text(18, 24, 600).c(colors.textStrong),
            const SizedBox(height: 16),
            _planCard(context, sub, isPremium),
            const SizedBox(height: 12),
            _detailsCard(context, sub, isPremium),
            if (sub?.status == SubscriptionStatus.cancelled &&
                sub?.endsAt != null) ...[
              const SizedBox(height: 10),
              _note(
                context,
                'sub_cancelled_note'.tr(
                  namedArgs: {'date': _formatDate(sub!.endsAt!)},
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (isPremium)
              ..._premiumActions(context, sub)
            else
              ..._freeActions(context),
          ],
        ),
      ),
    );
  }

  /// 1. Current plan — readable in one glance.
  Widget _planCard(BuildContext context, MySubscription? sub, bool isPremium) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPremium ? colors.mintGreen : colors.strokeSoft,
          width: isPremium ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                'current_plan'.tr().text(12, 16, 500).c(colors.textSub),
                const SizedBox(height: 4),
                (isPremium ? 'plan_premium' : 'plan_free')
                    .tr()
                    .text(24, 28, 800)
                    .c(isPremium ? colors.accentSub : colors.textStrong),
                const SizedBox(height: 4),
                _planLine(sub, isPremium).text(13, 17, 500).c(colors.textSub),
              ],
            ),
          ),
          _statusPill(context, sub, isPremium),
        ],
      ),
    );
  }

  Widget _statusPill(BuildContext context, MySubscription? sub, bool premium) {
    final colors = context.colors;
    final cancelled = sub?.status == SubscriptionStatus.cancelled;
    final Color color = !premium
        ? colors.textSub
        : cancelled
        ? colors.errorBase
        : colors.green;
    final label = !premium
        ? 'plan_free'.tr()
        : cancelled
        ? 'status_cancelled'.tr()
        : 'status_active'.tr();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 7,
            width: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          label.text(12, 14, 700).c(color),
        ],
      ),
    );
  }

  /// 2–3. Status and next payment, always shown — "none" is an answer too.
  Widget _detailsCard(BuildContext context, MySubscription? sub, bool premium) {
    final colors = context.colors;
    final loading = sub == null && premium;
    final cancelled = sub?.status == SubscriptionStatus.cancelled;

    final rows = <(String, String, Color?)>[
      (
        'sub_status'.tr(),
        !premium
            ? 'plan_free'.tr()
            : cancelled
            ? 'status_cancelled'.tr()
            : 'status_active'.tr(),
        !premium
            ? null
            : cancelled
            ? colors.errorBase
            : colors.green,
      ),
      (
        'next_payment'.tr(),
        sub?.autoRenew == true && sub?.nextPaymentAt != null
            ? _formatDate(sub!.nextPaymentAt!)
            : 'sub_no_payment'.tr(),
        null,
      ),
      if (premium && sub?.endsAt != null && sub?.autoRenew != true)
        ('sub_ends_at'.tr(), _formatDate(sub!.endsAt!), null),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.strokeSoft),
      ),
      child: loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              children: [
                for (int i = 0; i < rows.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: colors.strokeSoft),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      children: [
                        rows[i].$1.text(14, 18, 400).c(colors.textSub),
                        const Spacer(),
                        rows[i].$2
                            .text(14, 18, 600)
                            .c(rows[i].$3 ?? colors.textStrong),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _note(BuildContext context, String text) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, size: 16, color: colors.textSub),
        const SizedBox(width: 6),
        Expanded(child: text.text(12, 16, 400).c(colors.textSub)),
      ],
    );
  }

  List<Widget> _premiumActions(BuildContext context, MySubscription? sub) {
    final colors = context.colors;
    final store = sub?.managedByStore ?? false;
    return [
      Button(
        text: 'change_plan'.tr(),
        type: ButtonType.secondary,
        onPressed: () => store
            ? _openStoreSubscriptions()
            : _open(context, const PremiumFeaturesRoute()),
      ),
      if (store) ...[
        const SizedBox(height: 6),
        TextButton(
          onPressed: _openStoreSubscriptions,
          child:
              (Platform.isIOS ? 'manage_in_app_store' : 'manage_in_google_play')
                  .tr()
                  .text(14, 18, 600)
                  .c(colors.accentSub),
        ),
      ],
    ];
  }

  List<Widget> _freeActions(BuildContext context) {
    final colors = context.colors;
    return [
      _benefit(context, 'premium_feat_scans'.tr()),
      _benefit(context, 'premium_feat_plan'.tr()),
      const SizedBox(height: 16),
      Button(
        text: 'go_premium'.tr(),
        onPressed: () => _open(context, const PremiumFeaturesRoute()),
      ),
      const SizedBox(height: 6),
      TextButton(
        onPressed: () => _open(context, WalletRoute()),
        child: 'premium_with_coins'.tr().text(14, 18, 600).c(colors.accentSub),
      ),
    ];
  }

  Widget _benefit(BuildContext context, String text) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, size: 18, color: colors.accentSub),
          const SizedBox(width: 10),
          Expanded(child: text.text(14, 18, 500).c(colors.textStrong)),
        ],
      ),
    );
  }

  /// "Monthly · Payme", "Bought with coins", "Basic features"…
  String _planLine(MySubscription? sub, bool isPremium) {
    if (!isPremium) return 'free_plan_desc'.tr();
    if (sub == null) return '';
    switch (sub.source?.toLowerCase()) {
      case 'coins':
        return 'sub_source_coins'.tr();
      case 'referral':
        return 'sub_source_referral'.tr();
      case 'admin':
        return 'sub_source_gift'.tr();
    }
    final months = sub.durationInMonths;
    final plan = months == null
        ? 'plan_premium'.tr()
        : months == 1
        ? 'plan_monthly'.tr()
        : months == 12
        ? 'plan_yearly'.tr()
        : 'plan_n_months'.tr(namedArgs: {'count': '$months'});
    final provider = switch (sub.provider?.toLowerCase()) {
      'iap' => Platform.isIOS ? 'App Store' : 'Google Play',
      'payme' => 'Payme',
      'click' => 'Click',
      _ => null,
    };
    return provider == null ? plan : '$plan · $provider';
  }

  /// Store subscriptions are changed or cancelled only in the store itself.
  Future<void> _openStoreSubscriptions() => launchUrl(
    Uri.parse(
      Platform.isIOS
          ? 'https://apps.apple.com/account/subscriptions'
          : 'https://play.google.com/store/account/subscriptions?package=ai.calora.app',
    ),
    mode: LaunchMode.externalApplication,
  );

  void _open(BuildContext context, PageRouteInfo route) {
    Navigator.of(context).pop();
    context.router.push(route);
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.'
      '${d.month.toString().padLeft(2, '0')}.${d.year}';
}
