import 'package:calora/common/di/injection.dart';
import 'package:calora/common/enums/subscription_plan_type.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/service/revenuecat_service.dart';
import 'package:calora/domain/repo/premium/premium_repo.dart';
import 'package:calora/presentation/premium/management/premium_management.dart';
import 'package:collection/collection.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';
import 'package:url_launcher/url_launcher.dart';

@injectable
class PremiumManager extends Manager<PremiumState, PremiumEffect> {
  final PremiumRepo _premiumRepo;

  PremiumManager(this._premiumRepo) : super(const PremiumState()) {
    _init();
  }

  Future<void> _init() async {
    final isUzbekistan = await _premiumRepo.isUzbekistan;
    emit(state.copyWith(isUzbekistan: isUzbekistan));
    getPremiumPlans();
    getMyOrders();
    if (isUzbekistan) {
      _initializeMethods();
    } else {
      _initializeIapMethod();
    }
  }

  void _initializeIapMethod() {
    final iapMethod = PaymentMethod(icon: Assets.icons.payme, code: 'Iap');
    emit(
      state.copyWith(
        paymentMethods: [iapMethod],
        selectedPaymentMethod: iapMethod,
      ),
    );
  }

  void _initializeMethods() {
    final paymentMethods = [
      PaymentMethod(icon: Assets.icons.payme, code: 'Payme'),
      PaymentMethod(icon: Assets.icons.click, code: 'Click'),
    ];
    emit(state.copyWith(paymentMethods: paymentMethods));
  }

  void selectPlan(PlanModel plan) => emit(state.copyWith(selectedPlan: plan));

  void selectPaymentMethod(PaymentMethod method) =>
      emit(state.copyWith(selectedPaymentMethod: method));

  Future<void> getPremiumPlans() async =>
      await _premiumRepo.getPremiumPlans().handle(
        onStart: () => emit(state.copyWith(isGettingPremiumPlans: true)),
        onData: (data) {
          final plans = data.map((e) {
            if (e.duration == 1) {
              return PlanModel(
                title: Strings.monthlyPremium,
                price: e.fee ?? 0,
                packageMonth: e.duration ?? 0,
                isMostPopular: e.isPopular ?? false,
              );
            }
            return PlanModel(
              title: Strings.nMothPremium(month: e.duration ?? 0),
              price: e.fee ?? 0,
              packageMonth: e.duration ?? 0,
              isMostPopular: e.isPopular ?? false,
            );
          }).toList();

          PlanModel? initialPlan;
          try {
            initialPlan = plans.firstWhere((plan) => plan.isMostPopular);
          } catch (e) {
            initialPlan = plans.isNotEmpty ? plans.first : null;
          }
          emit(
            state.copyWith(
              isGettingPremiumPlans: false,
              plans: plans,
              selectedPlan: initialPlan,
            ),
          );
        },
        onError: (error) => emit(state.copyWith(isGettingPremiumPlans: false)),
      );

  Future<void> getMyOrders() async => await _premiumRepo.getMyOrders().handle(
    onStart: () => emit(state.copyWith(isGettingOrders: true)),
    onData: (data) {
      final pendingOrder = data.isNotEmpty
          ? data.firstWhere(
              (e) => e.status?.trim().toLowerCase() == 'pending',
              orElse: () => data.first,
            )
          : null;
      final selectedMethod = pendingOrder != null
          ? state.paymentMethods.firstWhereOrNull(
              (m) => m.code == pendingOrder.provider,
            )
          : null;
      emit(
        state.copyWith(
          isGettingOrders: false,
          myOrders: data,
          isPaymentPending: pendingOrder != null,
          selectedPaymentMethod: selectedMethod ?? state.selectedPaymentMethod,
        ),
      );
    },
    onError: (_) => emit(state.copyWith(isGettingOrders: false)),
  );

  void restoreOriginalPrices() {
    final restoredPlans = state.plans.map((plan) {
      return PlanModel(
        title: plan.title,
        price: plan.actualPrice ?? plan.price,
        packageMonth: plan.packageMonth,
        isMostPopular: plan.isMostPopular,
      );
    }).toList();

    PlanModel? newSelectedPlan;
    try {
      newSelectedPlan = restoredPlans.firstWhere((plan) => plan.isMostPopular);
    } catch (e) {
      newSelectedPlan = restoredPlans.isNotEmpty ? restoredPlans.first : null;
    }

    emit(
      state.copyWith(
        isGettingPromoCodeValue: false,
        promoCodeValue: null,
        plans: restoredPlans,
        selectedPlan: newSelectedPlan,
      ),
    );
  }

  Future<void> getPromoCodeValue(String code) async {
    if (code.trim().isEmpty) return restoreOriginalPrices();

    await _premiumRepo
        .getPromoCodeAmount(code: code)
        .handle(
          onStart: () => emit(state.copyWith(isGettingPromoCodeValue: true)),
          onData: (data) {
            if (data.id != null && data.amount != null) {
              final discountedPlans = state.plans.map((plan) {
                final discountedPrice =
                    (plan.actualPrice ?? plan.price) - (data.amount ?? 0);
                return PlanModel(
                  title: plan.title,
                  price: discountedPrice > 0 ? discountedPrice : 0,
                  actualPrice: plan.actualPrice ?? plan.price,
                  packageMonth: plan.packageMonth,
                  isMostPopular: plan.isMostPopular,
                );
              }).toList();

              PlanModel? newSelectedPlan;
              try {
                newSelectedPlan = discountedPlans.firstWhere(
                  (plan) => plan.isMostPopular,
                );
              } catch (e) {
                newSelectedPlan = discountedPlans.isNotEmpty
                    ? discountedPlans.first
                    : null;
              }

              emit(
                state.copyWith(
                  isGettingPromoCodeValue: false,
                  promoCodeValue: data,
                  plans: discountedPlans,
                  selectedPlan: newSelectedPlan,
                ),
              );
            } else {
              restoreOriginalPrices();
              publish(const PremiumEffect.invalidPromoCode());
            }
          },
          onError: (_) => restoreOriginalPrices(),
        );
  }

  Future<void> orderSubscription() async => await _premiumRepo
      .orderSubscription(
        provider: state.selectedPaymentMethod?.code ?? '',
        plan: SubscriptionPlanType.premium.toApi(),
        orderMonth: state.selectedPlan?.packageMonth ?? -1,
        couponId: state.promoCodeValue?.id,
      )
      .handle(
        onStart: () => emit(state.copyWith(isOrderingSubscription: true)),
        onData: (link) {
          emit(
            state.copyWith(
              isOrderingSubscription: false,
              paymentLink: link.paymentLink ?? '',
            ),
          );
          if (link.paymentRequired ?? true) {
            if (state.selectedPaymentMethod?.code == 'Iap')
              _openIap(state.selectedPlan!);
            else
              _openPaymentUrl(link.paymentLink ?? '');
          } else {
            publish(const PremiumEffect.subscriptionSuccess());
          }
        },
        onError: (error) => emit(state.copyWith(isOrderingSubscription: false)),
      );

  Future<void> deleteOrder() async => _premiumRepo
      .deleteOrder(orderId: state.myOrders.first.id ?? -1)
      .handle(
        onStart: () => emit(state.copyWith(isDeletingOrder: true)),
        onData: (_) => emit(
          state.copyWith(isDeletingOrder: false, isPaymentPending: false),
        ),
        onError: (_) => emit(state.copyWith(isDeletingOrder: false)),
      );

  Future<void> getPaymentLink() async => await _premiumRepo
      .getPaymentLink(orderId: state.myOrders.first.id ?? -1)
      .handle(
        onStart: () => emit(state.copyWith(isGettingPaymentLink: true)),
        onData: (link) {
          emit(state.copyWith(isGettingPaymentLink: false, paymentLink: link));
          _openPaymentUrl(link);
        },
        onError: (error) => emit(state.copyWith(isGettingPaymentLink: false)),
      );

  Future<void> _openPaymentUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          publish(
            PremiumEffect.openPaymentUrlFailure(
              Strings.couldNotLaunchPaymentUrl,
            ),
          );
        }
      } else {
        publish(
          PremiumEffect.openPaymentUrlFailure(Strings.couldNotLaunchPaymentUrl),
        );
      }
    } catch (e) {
      publish(PremiumEffect.openPaymentUrlFailure(e.toString()));
    }
  }

  void _openIap(PlanModel plan) async {
    final purchased = await getIt<RevenueCatService>().purchase(plan);
    if (purchased) {
      publish(PremiumEffect.subscriptionSuccess());
    }
  }
}
