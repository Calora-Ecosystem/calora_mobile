import 'package:auto_route/auto_route.dart';
import 'package:calora/common/di/injection.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/domain/model/premium/my_subscription.dart';
import 'package:calora/domain/repo/premium/premium_repo.dart';
import 'package:calora/presentation/app/app/management/app_manager.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

/// Subscription info panel (bottom sheet) opened from Profile. Gives the user a
/// transparent view of their plan — current tier, status and next payment for
/// premium, or a clear upgrade path for free — matching store requirements and
/// cutting subscription-related support questions.
///
/// Billing details come from `GET billing/subscription/my`; until they load
/// the tier is taken from [AppManager] so the header never flickers.
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          'subscription_title'
              .tr()
              .text(18, 24, 600)
              .c(context.colors.textStrong),
          const SizedBox(height: 16),
          _planHeader(context, isPremium),
          const SizedBox(height: 16),
          if (isPremium)
            ..._premiumBody(context)
          else
            _FreeUpsell(onGoPremium: () => _openPremium(context)),
        ],
      ),
    );
  }

  Widget _planHeader(BuildContext context, bool isPremium) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isPremium ? null : colors.backgroundElevation,
        gradient: isPremium
            ? RadialGradient(
                center: const Alignment(1.3, -0.8),
                radius: 1.6,
                colors: [colors.honeydew, colors.mintGreen],
                stops: const [0.0, 1.0],
              )
            : null,
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: isPremium
                  ? colors.white.withValues(alpha: 0.22)
                  : colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Assets.icons.crown.svg(
              height: 22,
              colorFilter: ColorFilter.mode(
                isPremium ? colors.textWhite : colors.accentSub,
                BlendMode.srcIn,
              ),
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
                    .c(
                      isPremium
                          ? colors.textWhite.withValues(alpha: 0.9)
                          : colors.textSub,
                    ),
                const SizedBox(height: 2),
                (isPremium ? 'plan_premium' : 'plan_free')
                    .tr()
                    .text(18, 22, 700)
                    .c(isPremium ? colors.textWhite : colors.textStrong),
              ],
            ),
          ),
          if (isPremium)
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
        onPressed: () => _openPremium(context),
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

  void _openPremium(BuildContext context) {
    Navigator.of(context).pop();
    context.router.push(const PremiumFeaturesRoute());
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.'
      '${d.month.toString().padLeft(2, '0')}.${d.year}';
}

/// Free-tier upsell with a gently floating 3D badge and a benefit list — a
/// hand-crafted showcase rather than a flat "you're on free" note.
class _FreeUpsell extends StatefulWidget {
  const _FreeUpsell({required this.onGoPremium});

  final VoidCallback onGoPremium;

  @override
  State<_FreeUpsell> createState() => _FreeUpsellState();
}

class _FreeUpsellState extends State<_FreeUpsell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: AnimatedBuilder(
            animation: _float,
            builder: (context, child) {
              final t = Curves.easeInOut.transform(_float.value);
              return Transform.translate(
                offset: Offset(0, -8 * t),
                child: child,
              );
            },
            child: Assets.images.premiumFire.image(height: 96),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: 'unlock_premium'.tr().text(18, 24, 700).c(colors.textStrong),
        ),
        const SizedBox(height: 16),
        _feature(context, Icons.bolt_rounded, 'premium_feat_scans'.tr()),
        _feature(context, Icons.tune_rounded, 'premium_feat_plan'.tr()),
        _feature(
          context,
          Icons.monetization_on_rounded,
          'premium_feat_coins'.tr(),
        ),
        const SizedBox(height: 18),
        Button(text: 'go_premium'.tr(), onPressed: widget.onGoPremium),
      ],
    );
  }

  Widget _feature(BuildContext context, IconData icon, String text) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: colors.lightGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: colors.accentSub),
          ),
          const SizedBox(width: 12),
          Expanded(child: text.text(14, 18, 500).c(colors.textStrong)),
          Icon(Icons.check_rounded, size: 18, color: colors.accentSub),
        ],
      ),
    );
  }
}
