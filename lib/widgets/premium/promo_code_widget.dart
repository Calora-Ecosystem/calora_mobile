import 'dart:developer';

import 'package:calora/common/base/manager_builder.dart';
import 'package:calora/common/extensions/color_extension.dart';
import 'package:calora/common/widgets/snack_bar/custom_snack_bar.dart';
import 'package:calora/presentation/premium/management/premium_management.dart';
import 'package:flutter/cupertino.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/text_field/common_text_field.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/premium/management/premium_manager.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

class PromoCodeWidget extends StatefulWidget {
  const PromoCodeWidget({super.key});

  @override
  State<PromoCodeWidget> createState() => _PromoCodeWidgetState();
}

class _PromoCodeWidgetState extends State<PromoCodeWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ManagerBuilder<PremiumState, PremiumEffect>(
      manager: context.read<PremiumManager>(),
      properties: (state) => [state.isIap],
      builder: (context, state) =>
          state.isIap ? _offerCodeButton(context) : _couponField(context),
    );
  }

  /// IAP flow: Apple offer codes are redeemed in a native StoreKit sheet,
  /// so there is nothing to type here — the whole row is a button. The
  /// backend coupon endpoint is deliberately not reachable from this
  /// branch; it discounts a UZS fee the App Store will never charge.
  Widget _offerCodeButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<PremiumManager>().redeemOfferCode(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 48,
        padding: const EdgeInsets.only(left: 16, right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colors.strokeSoft, width: 1.5),
        ),
        child: Row(
          children: [
            Strings.promokod.text(16, 20, 400).c(context.colors.textSub),
            const Spacer(),
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: context.colors.accentSub,
              ),
              // Reuses the coupon field's own label. `translations.csv`
              // is generated from the Google Sheet in `strings.dart`, so
              // a dedicated "Redeem" string has to be added there and the
              // `version:` bumped — it can't be introduced from code.
              child: Strings.apply.text(12, 14, 400).c(context.colors.white),
            ),
          ],
        ),
      ),
    );
  }

  /// Payme / Click flow: backend coupon codes, applied server-side.
  Widget _couponField(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        children: [
          CommonTextField(
            controller: _controller,
            onChanged: (value) {
              if (value.isEmpty || value.endsWith(' ')) return;
              final premiumManager = context.read<PremiumManager>();
              premiumManager.restoreOriginalPrices();
            },
            hint: Strings.promokod,
            contentPadding: const EdgeInsets.only(left: 16, right: 100),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => context.read<PremiumManager>().getPromoCodeValue(_controller.text.trim()),
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: context.colors.accentSub,
                ),
                child: ManagerBuilder<PremiumState, PremiumEffect>(
                  manager: context.read<PremiumManager>(),
                  properties: (state) => [state.isGettingPromoCodeValue],
                  builder: (context, state) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Opacity(
                          opacity: state.isGettingPromoCodeValue ? 0.0 : 1.0,
                          child: Strings.apply.text(12, 14, 400).c(context.colors.white),
                        ),
                        if (state.isGettingPromoCodeValue) const CupertinoActivityIndicator(color: Colors.white),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
