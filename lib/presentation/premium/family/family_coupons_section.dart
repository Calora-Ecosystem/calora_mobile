import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/domain/model/premium/family_code.dart';
import 'package:calora/domain/model/premium/family_coupon.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/premium/family/family_code_sheet.dart';
import 'package:calora/presentation/premium/family/management/family_coupons_manager.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

class FamilyCouponsSection
    extends Managed<FamilyCouponsManager, List<FamilyCoupon>, Never> {
  const FamilyCouponsSection({super.key});

  @override
  Widget builder(
    BuildContext context,
    FamilyCouponsManager manager,
    List<FamilyCoupon> coupons,
  ) => FamilyCouponsList(coupons: coupons);
}

class FamilyCouponsList extends StatelessWidget {
  const FamilyCouponsList({super.key, required this.coupons});

  final List<FamilyCoupon> coupons;

  @override
  Widget build(BuildContext context) {
    if (coupons.isEmpty) return const SizedBox.shrink();
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        decoration: BoxDecoration(
          color: colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.strokeSoft),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
              child: 'family_codes_title'
                  .tr()
                  .text(12, 16, 500)
                  .c(colors.textSub),
            ),
            for (final (index, coupon) in coupons.indexed) ...[
              if (index > 0)
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: colors.strokeSoft,
                ),
              _CouponTile(coupon: coupon),
            ],
          ],
        ),
      ),
    );
  }
}

class _CouponTile extends StatelessWidget {
  const _CouponTile({required this.coupon});

  final FamilyCoupon coupon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final active = coupon.status == FamilyCodeStatus.active;
    final expired = coupon.status == FamilyCodeStatus.expired;
    final (icon, label, color) = _status(context);

    return InkWell(
      onTap: active
          ? () => FamilyCodeSheet.show(context, coupon: coupon)
          : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coupon.code,
                    style: TextStyle(
                      fontSize: 16,
                      height: 20 / 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: active ? colors.textStrong : colors.textSub,
                      decoration: expired ? TextDecoration.lineThrough : null,
                      decorationColor: colors.textSub,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(icon, size: 14, color: color),
                      const SizedBox(width: 5),
                      Expanded(child: label.text(12, 16, 500).c(color)),
                    ],
                  ),
                  for (final user in coupon.usedByUsers)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: _UserRow(user: user),
                    ),
                ],
              ),
            ),
            if (active)
              Icon(Icons.chevron_right_rounded, color: colors.iconSoft),
          ],
        ),
      ),
    );
  }

  (IconData, String, Color) _status(BuildContext context) {
    final colors = context.colors;
    return switch (coupon.status) {
      FamilyCodeStatus.active => (
        Icons.schedule_rounded,
        coupon.expireAt == null
            ? 'status_active'.tr()
            : 'family_code_active_until'.tr(
                namedArgs: {'date': _formatDate(coupon.expireAt!)},
              ),
        colors.accentSub,
      ),
      FamilyCodeStatus.redeemed => (
        Icons.verified_rounded,
        [
          'family_code_redeemed'.tr(),
          if (coupon.usedAt case final usedAt?) _formatDate(usedAt),
        ].join(' · '),
        colors.accentSub,
      ),
      FamilyCodeStatus.expired => (
        Icons.timer_off_rounded,
        'family_code_expired'.tr(),
        colors.errorBase,
      ),
    };
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.user});

  final CouponUser user;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final phone = formatCouponPhone(user.phone);
    final name = user.name.isNotEmpty ? user.name : phone;
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: colors.lightGreen,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.person_rounded, size: 15, color: colors.accentSub),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: name
              .text(13, 18, 600)
              .c(colors.textStrong)
              .copyWith(maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        if (user.name.isNotEmpty && phone.isNotEmpty) ...[
          const SizedBox(width: 8),
          phone.text(12, 16, 400).c(colors.textSub).copyWith(maxLines: 1),
        ],
      ],
    );
  }
}

String formatCouponPhone(String phone) {
  final match = RegExp(
    r'^\+?998(\d{2})(\d{3})(\d{2})(\d{2})$',
  ).firstMatch(phone.replaceAll(RegExp(r'[\s()-]'), ''));
  if (match == null) return phone;
  return '+998 ${match[1]} ${match[2]} ${match[3]} ${match[4]}';
}

String _formatDate(DateTime date) => DateFormat('dd.MM.yyyy').format(date);
