import 'package:calora/common/enums/subscription_plan_type.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
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
    getMyOrders();
    _initialize();
  }

  void _initialize() {
    final plans = [
      PlanModel(title: Strings.monthlyPremium, price: 49000, packageMonth: 1),
      PlanModel(title: Strings.nMothPremium(month: 3), actualPrice: 150000, price: 142000, packageMonth: 3),
      PlanModel(
        title: Strings.nMothPremium(month: 6),
        actualPrice: 300000,
        price: 270000,
        isMostPopular: true,
        packageMonth: 6,
      ),
      PlanModel(title: Strings.annualPremium, actualPrice: 600000, price: 480000, packageMonth: 12),
    ];

    final paymentMethods = [
      PaymentMethod(icon: Assets.icons.payme, code: 'Payme'),
      PaymentMethod(icon: Assets.icons.click, code: 'Click'),
    ];

    PlanModel? initialPlan;
    try {
      initialPlan = plans.firstWhere((plan) => plan.isMostPopular);
    } catch (e) {
      initialPlan = plans.isNotEmpty ? plans.first : null;
    }

    emit(state.copyWith(plans: plans, paymentMethods: paymentMethods, selectedPlan: initialPlan));
  }

  void selectPlan(PlanModel plan) => emit(state.copyWith(selectedPlan: plan));
  void selectPaymentMethod(PaymentMethod method) => emit(state.copyWith(selectedPaymentMethod: method));

  Future<void> _openPaymentUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          publish(PremiumEffect.openPaymentUrlFailure(Strings.couldNotLaunchPaymentUrl));
        }
      } else {
        publish(PremiumEffect.openPaymentUrlFailure(Strings.couldNotLaunchPaymentUrl));
      }
    } catch (e) {
      publish(PremiumEffect.openPaymentUrlFailure(e.toString()));
    }
  }

  Future<void> getMyOrders() async => await _premiumRepo.getMyOrders().handle(
    onStart: () => emit(state.copyWith(isGettingOrders: true)),
    onData: (data) {
      final pendingOrder = data.isNotEmpty
          ? data.firstWhere((e) => e.status?.trim().toLowerCase() == 'pending', orElse: () => data.first)
          : null;
      final selectedMethod = pendingOrder != null
          ? state.paymentMethods.firstWhereOrNull((m) => m.code == pendingOrder.provider)
          : null;
      emit(
        state.copyWith(
          isGettingOrders: false,
          myOrders: data,
          isPaymentPending: pendingOrder != null,
          selectedPaymentMethod: selectedMethod,
        ),
      );
    },
    onError: (_) => emit(state.copyWith(isGettingOrders: false)),
  );

  Future<void> orderSubscription() async => await _premiumRepo
      .orderSubscription(
        provider: state.selectedPaymentMethod?.code ?? '',
        plan: SubscriptionPlanType.premium.toApi(),
        orderMonth: state.selectedPlan?.packageMonth ?? -1,
      )
      .handle(
        onStart: () => emit(state.copyWith(isOrderingSubscription: true)),
        onData: (link) {
          emit(state.copyWith(isOrderingSubscription: false, paymentLink: link));
          _openPaymentUrl(link);
        },
        onError: (error) => emit(state.copyWith(isOrderingSubscription: false)),
      );

  Future<void> deleteOrder() async => _premiumRepo
      .deleteOrder(orderId: state.myOrders.first.id ?? -1)
      .handle(
        onStart: () => emit(state.copyWith(isDeletingOrder: true)),
        onData: (_) => emit(state.copyWith(isDeletingOrder: false)),
        onError: (error) {
          emit(state.copyWith(isDeletingOrder: false));
        },
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
}
