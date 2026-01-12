import 'package:calora/common/extensions/color_extension.dart';
import 'package:calora/common/extensions/number_extension/number_extension.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/common/widgets/containers/bottom_box.dart';
import 'package:calora/common/widgets/sheets/default_bottom_sheet.dart';
import 'package:calora/common/widgets/text_field/common_text_field.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/premium/management/premium_management.dart';
import 'package:calora/presentation/premium/management/premium_manager.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

class PremiumSheet extends Managed<PremiumManager, PremiumState, PremiumEffect> {
  const PremiumSheet({super.key});

  Widget builder(context, manager, state) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DefaultBottomSheet(
        titleWidget: Strings.chooseRightPackage.text(20, 24, 600).c(context.colors.textPrimary),
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...List.generate(
                      state.plans.length,
                      (index) {
                        final plan = state.plans[index];
                        return _planCard(
                          context: context,
                          plan: plan,
                          isSelected: state.selectedPlanIndex == index,
                          onTap: () => manager.selectPlan(index),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      height: 48,
                      child: Stack(
                        children: [
                          CommonTextField(
                            hint: Strings.promokod,
                            contentPadding: const EdgeInsets.only(left: 16, right: 100),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {},
                              child: Container(
                                height: 32,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: context.colors.accentSub,
                                ),
                                child: Strings.apply.text(12, 14, 400).c(context.colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Strings.choosePaymentMethod.text(20, 24, 600).c(context.colors.textPrimary),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisExtent: 60,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
                      itemCount: state.paymentMethods.length,
                      itemBuilder: (context, index) {
                        final method = state.paymentMethods[index];
                        final isSelected = state.selectedPaymentMethodIndex == index;
                        return GestureDetector(
                          onTap: () => manager.selectPaymentMethod(index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: isSelected
                                  ? context.colors.accentSub.withOpacityLevel(0.2)
                                  : const Color(0x0F000000),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                method.icon.svg(),
                                if (method.displayName != null) ...[
                                  const SizedBox(width: 8),
                                  method.displayName!.text(14, 18, 500).c(context.colors.textStrong),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            BottomBox(
              child: Button(
                height: 40,
                text: Strings.purchase,
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _planCard({
    required BuildContext context,
    required Plan plan,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            Container(height: 68),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 56,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isSelected ? context.colors.white : context.colors.backgroundElevation,
                  border: isSelected ? Border.all(color: context.colors.accentSub) : null,
                ),
                child: Row(
                  children: [
                    Container(
                      height: 16,
                      width: 16,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: isSelected ? context.colors.accentSub : context.colors.backgroundElevation,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: isSelected ? context.colors.iconSoft : Colors.transparent),
                      ),
                      child: isSelected
                          ? Container(
                              decoration: BoxDecoration(shape: BoxShape.circle, color: context.colors.white),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    plan.title.text(14, 18, 500).c(context.colors.textPrimary),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        '${plan.price.formatPrice()} UZS'.text(14, 18, 500).c(context.colors.textPrimary),
                        if (plan.actualPrice != plan.price)
                          '${plan.actualPrice.formatPrice()} UZS'
                              .text(12, 14, 500)
                              .c(context.colors.textSub)
                              .copyWith(
                                textHeightBehavior: const TextHeightBehavior(
                                  applyHeightToFirstAscent: false,
                                  applyHeightToLastDescent: false,
                                ),
                                style: TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  height: 14 / 12,
                                ),
                              ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (plan.isMostPopular)
              Positioned(
                top: 0,
                left: 16,
                child: Container(
                  height: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: context.colors.accentSub,
                  ),
                  child: Row(
                    children: [
                      Assets.icons.fire.svg(),
                      const SizedBox(width: 10),
                      Strings.bestOffer.text(10, 10, 400).c(context.colors.white),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
