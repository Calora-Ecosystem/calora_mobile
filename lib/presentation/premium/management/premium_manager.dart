import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/presentation/premium/management/premium_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class PremiumManager extends Manager<PremiumState, PremiumEffect> {
  PremiumManager() : super(const PremiumState()) {
    _initialize();
  }

  void _initialize() {
    final plans = [
      Plan(title: 'Oylik Premium', actualPrice: 162000, price: 142000),
      Plan(title: '3 oylik Premium', actualPrice: 162000, price: 142000),
      Plan(title: '6 oylik Premium', actualPrice: 162000, price: 142000, isMostPopular: true),
      Plan(title: 'Yillik Premium', actualPrice: 162000, price: 142000),
    ];

    final paymentMethods = [
      PaymentMethod(icon: Assets.icons.payme, code: 'payme'),
      PaymentMethod(icon: Assets.icons.click, code: 'click'),
      PaymentMethod(icon: Assets.icons.apple, code: 'apple', displayName: 'Apple Pay'),
      PaymentMethod(icon: Assets.icons.masterVisaCard, code: 'masterVisa'),
    ];

    int bestSellerIndex = plans.indexWhere((plan) => plan.isMostPopular);
    int initialPlanIndex;
    if (bestSellerIndex != -1) {
      initialPlanIndex = bestSellerIndex;
    } else if (plans.isNotEmpty) {
      initialPlanIndex = 0;
    } else {
      initialPlanIndex = -1;
    }

    emit(
      state.copyWith(
        plans: plans,
        paymentMethods: paymentMethods,
        selectedPlanIndex: initialPlanIndex,
      ),
    );
  }

  void selectPlan(int index) {
    emit(state.copyWith(selectedPlanIndex: index));
  }

  void selectPaymentMethod(int index) {
    emit(state.copyWith(selectedPaymentMethodIndex: index));
  }
}
