import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/number_extension/number_extension.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/common/widgets/confetti/confetti.dart';
import 'package:calora/common/widgets/containers/bottom_box.dart';
import 'package:calora/common/widgets/loading/shimmer.dart';
import 'package:calora/common/widgets/sheets/default_bottom_sheet.dart';
import 'package:calora/common/widgets/snack_bar/custom_snack_bar.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/premium/management/premium_management.dart';
import 'package:calora/presentation/premium/management/premium_manager.dart';
import 'package:calora/widgets/premium/promo_code_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

class PremiumSheet
    extends Managed<PremiumManager, PremiumState, PremiumEffect> {
  PremiumSheet({super.key});

  @override
  void onFocusGained(BuildContext context, PremiumManager manager) {
    super.onFocusGained(context, manager);
    manager.getMyOrders();
  }

  @override
  void listener(
    BuildContext context,
    PremiumManager manager,
    PremiumEffect effect,
  ) {
    super.listener(context, manager, effect);
    effect.when(
      openPaymentUrlFailure: (error) => CustomSnackBar.show(context, error),
      deleteSubscriptionFailure: (error) => CustomSnackBar.show(context, error),
      invalidPromoCode: () =>
          CustomSnackBar.show(context, Strings.invalidPromoCode),
      subscriptionSuccess: () async {
        await PremiumConfettiOverlay.show(context);
        CustomSnackBar.showSuccess(context, Strings.subscriptionSuccess);
        context.router.maybePop();
      },
    );
  }

  Widget builder(context, manager, state) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DefaultBottomSheet(
        titleWidget: ShimmerWrapper(
          loading: state.isGettingOrders,
          type: ShimmerType.backgroundElevation,
          shimmerChild: ShimmerChild(height: 24, radius: 6, width: 150),
          child:
              (state.isPaymentPending
                      ? Strings.purchaseIsPending
                      : Strings.chooseRightPackage)
                  .text(20, 24, 600)
                  .c(context.colors.textPrimary),
        ),
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
                    Stack(
                      children: [
                        Column(
                          children: List.generate(
                            state.isGettingOrders || state.isGettingPremiumPlans
                                ? 3
                                : state.plans.length,
                            (index) {
                              if (state.isGettingOrders ||
                                  state.isGettingPremiumPlans) {
                                return ShimmerWrapper(
                                  loading: true,
                                  type: ShimmerType.backgroundElevation,
                                  shimmerChild: ShimmerChild(
                                    margin: const EdgeInsets.only(top: 16),
                                    height: 56,
                                    radius: 16,
                                    width: double.infinity,
                                  ),
                                  child: const SizedBox.shrink(),
                                );
                              }
                              final plan = state.plans[index];
                              return _planCard(
                                context: context,
                                plan: plan,
                                isSelected: state.selectedPlan == plan,
                                onTap: () => manager.selectPlan(plan),
                              );
                            },
                          ),
                        ),

                        if (state.isPaymentPending)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  child: Assets.icons.pendingClock.svg(),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (!state.isPaymentPending && state.isUzbekistan) ...[
                      const SizedBox(height: 16),
                      PromoCodeWidget(),
                    ],
                    if (state.isUzbekistan || kDebugMode) ...[
                      const SizedBox(height: 16),
                      if (state.isPaymentPending &&
                          state.selectedPaymentMethod != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Strings.chosenPaymentType
                                .text(20, 24, 600)
                                .c(context.colors.textPrimary),
                            const SizedBox(height: 8),
                            _buildPaymentMethodCard(
                              context,
                              manager,
                              state.selectedPaymentMethod!,
                              true,
                              state.isGettingOrders,
                            ),
                          ],
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Strings.choosePaymentMethod
                                .text(20, 24, 600)
                                .c(context.colors.textPrimary),
                            const SizedBox(height: 8),
                            GridView.builder(
                              shrinkWrap: true,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisExtent: 60,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                  ),
                              itemCount: state.paymentMethods.length,
                              itemBuilder: (context, index) {
                                if (state.isGettingOrders) {
                                  return ShimmerWrapper(
                                    loading: true,
                                    type: ShimmerType.backgroundElevation,
                                    shimmerChild: ShimmerChild(
                                      height: 60,
                                      radius: 12,
                                    ),
                                    child: const SizedBox.shrink(),
                                  );
                                }
                                final method = state.paymentMethods[index];
                                final isSelected =
                                    state.selectedPaymentMethod == method;
                                return _buildPaymentMethodCard(
                                  context,
                                  manager,
                                  method,
                                  isSelected,
                                  state.isGettingOrders,
                                );
                              },
                            ),
                          ],
                        ),
                    ],
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
            BottomBox(
              child: state.isPaymentPending
                  ? Column(
                      children: [
                        Button(
                          height: 40,
                          text: Strings.continuePurchase,
                          loading: state.isGettingPaymentLink,
                          onPressed: () => manager.getPaymentLink(),
                        ),
                        const SizedBox(height: 12),
                        Button(
                          height: 40,
                          text: Strings.cancel,
                          loading: state.isDeletingOrder,
                          backgroundColor: context.colors.errorBase,
                          onPressed: () => manager.deleteOrder(),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Button(
                          height: 40,
                          text: Strings.purchase,
                          enabled:
                              state.selectedPlan != null &&
                              (state.selectedPaymentMethod != null ||
                                  !state.isUzbekistan),
                          loading: state.isOrderingSubscription,
                          onPressed: () => manager.orderSubscription(),
                        ),
                        if (state.selectedPaymentMethod?.code == 'Iap') ...[
                          const SizedBox(height: 12),
                          Button(
                            height: 40,
                            text: 'Restore purchase',
                            type: ButtonType.secondary,
                            enabled:
                            state.selectedPlan != null &&
                                (state.selectedPaymentMethod != null ||
                                    !state.isUzbekistan),
                            loading: state.isOrderingSubscription,
                            onPressed: () => manager.orderSubscription(restore: true),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _planCard({
    required BuildContext context,
    required PlanModel plan,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isSelected
                      ? context.colors.white
                      : context.colors.backgroundElevation,
                  border: Border.all(
                    color: isSelected
                        ? context.colors.accentSub
                        : context.colors.backgroundElevation,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 16,
                      width: 16,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? context.colors.accentSub
                            : context.colors.backgroundElevation,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: isSelected
                              ? context.colors.accentSub
                              : context.colors.iconSoft,
                        ),
                      ),
                      child: isSelected
                          ? Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: context.colors.white,
                              ),
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
                        '${plan.price.formatPrice()} UZS'
                            .text(14, 18, 500)
                            .c(context.colors.textPrimary),
                        if (plan.actualPrice != null &&
                            plan.actualPrice != plan.price)
                          Text(
                            '${plan.actualPrice!.formatPrice()} UZS',
                            style: TextStyle(
                              color: context.colors.textSub,
                              decoration: TextDecoration.lineThrough,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              height: 14 / 12,
                            ),
                            textHeightBehavior: const TextHeightBehavior(
                              applyHeightToFirstAscent: false,
                              applyHeightToLastDescent: false,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: context.colors.accentSub,
                  ),
                  child: Row(
                    children: [
                      Assets.icons.fire.svg(),
                      const SizedBox(width: 10),
                      Strings.bestOffer
                          .text(10, 10, 400)
                          .c(context.colors.white),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(
    BuildContext context,
    PremiumManager manager,
    PaymentMethod method,
    bool isSelected,
    bool isLoading,
  ) {
    if (isLoading) {
      return ShimmerWrapper(
        loading: true,
        type: ShimmerType.backgroundElevation,
        shimmerChild: ShimmerChild(height: 60, radius: 12),
        child: const SizedBox.shrink(),
      );
    }
    return GestureDetector(
      onTap: () => manager.selectPaymentMethod(method),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? context.colors.white : const Color(0x0F000000),
          border: Border.all(
            color: isSelected
                ? context.colors.accentSub
                : context.colors.backgroundElevation,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            method.icon.svg(),
            if (method.displayName != null) ...[
              const SizedBox(width: 8),
              method.displayName!
                  .text(14, 18, 500)
                  .c(context.colors.textStrong),
            ],
          ],
        ),
      ),
    );
  }
}
