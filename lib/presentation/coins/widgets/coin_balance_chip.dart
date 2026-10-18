import 'package:calora/common/extensions/number_extension/number_extension.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class CoinBalanceChip extends StatelessWidget {
  const CoinBalanceChip({
    super.key,
    required this.balance,
    required this.onTap,
  });

  final int? balance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final balance = this.balance;

    return Semantics(
      button: true,
      label: balance == null
          ? 'wallet_title'.tr()
          : '${'coin_balance'.tr()}: $balance ${'coin_unit'.tr()}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 40,
          padding: const EdgeInsetsDirectional.fromSTEB(5, 5, 8, 5),
          decoration: BoxDecoration(
            color: colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 30,
                width: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colors.mintGreen, colors.accentSub],
                  ),
                ),
                child: Icon(
                  Icons.monetization_on_rounded,
                  color: colors.textWhite,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: balance == null
                    ? _placeholder(context)
                    : _AnimatedBalance(
                        key: const ValueKey('balance'),
                        balance: balance,
                      ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.iconSoft,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) => Container(
    key: const ValueKey('placeholder'),
    height: 12,
    width: 28,
    decoration: BoxDecoration(
      color: context.colors.backgroundElevation,
      borderRadius: BorderRadius.circular(6),
    ),
  );
}

class _AnimatedBalance extends StatelessWidget {
  const _AnimatedBalance({super.key, required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(end: balance),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) =>
          value.toPrettyFormat().text(16, 20, 700).c(context.colors.textStrong),
    );
  }
}
