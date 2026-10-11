import 'dart:math';
import 'dart:async';

import 'package:calora/common/di/injection.dart';
import 'package:calora/common/di/network/interceptor/token_interceptor.dart';
import 'package:calora/common/enums/subscription_plan_type.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/service/facebook_analytics_service.dart';
import 'package:calora/common/service/revenuecat_service.dart';
import 'package:calora/domain/model/premium/family_code.dart';
import 'package:calora/domain/model/premium/family_coupon.dart';
import 'package:calora/domain/model/premium/premium_plan_model.dart';
import 'package:calora/domain/model/premium/promo_code_model.dart';
import 'package:calora/domain/repo/common/common_repo.dart';
import 'package:calora/domain/repo/premium/premium_repo.dart';
import 'package:calora/presentation/premium/family/family_code_error.dart';
import 'package:calora/presentation/premium/management/premium_management.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:management/management.dart';
import 'package:purchases_flutter/purchases_flutter.dart' show StoreProduct;
import 'package:url_launcher/url_launcher.dart';

@injectable
class PremiumManager extends Manager<PremiumState, PremiumEffect>
    with WidgetsBindingObserver {
  final PremiumRepo _premiumRepo;
  final CommonRepo _commonRepo;

  StreamSubscription<bool>? _countrySubscription;

  bool _awaitingExternalPayment = false;
  bool _checkingExternalPayment = false;
  Timer? _paymentPollTimer;
  int _paymentPollTicks = 0;
  static const Duration _paymentPollInterval = Duration(seconds: 5);
  static const int _paymentPollMaxTicks = 24;

  bool _awaitingOfferCode = false;

  /// Family codes the user had before paying for the family plan. The
  /// family payment counts as done when a code outside this set shows up —
  /// "is the user Premium" can't tell, a Premium user may buy it too. Null
  /// when not paying for the family plan (or the lookup failed).
  Set<String>? _familyCodesBefore;

  FamilyCoupon? issuedFamilyCoupon;

  static const String _playRedeemUrl = 'https://play.google.com/redeem';

  bool _iapPricesRequested = false;

  final Map<int, StoreProduct> _iapProducts = {};
  bool _paywallViewLogged = false;

  PremiumManager(this._premiumRepo, this._commonRepo)
    : super(const PremiumState()) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed &&
        _awaitingExternalPayment) {
      unawaited(_checkExternalPayment());
    }
  }

  @override
  void initialize() {
    _countrySubscription = _commonRepo.getIsUzbekistan().cacheAndNetwork.listen(
      _applyIsUzbekistan,
      onError: (e, st) => getIt<Logger>().e(e.toString(), stackTrace: st),
    );
    getMyOrders();
  }

  void showPlans(List<PremiumPlanModel> packages, {int? selectedId}) {
    final plans = packages.map(_toPlanModel).toList();
    emit(
      state.copyWith(
        isFamily: packages.any((package) => package.isFamily),
        plans: plans,
        selectedPlan: _pick(plans, selectedId),
        referralDiscountPercent: packages
            .map((package) => package.referralDiscountPercent)
            .fold(0, max),
      ),
    );
  }

  static PlanModel _toPlanModel(PremiumPlanModel package) {
    final months = package.duration;
    final title = switch ((package.isFamily, months)) {
      (true, 1) => 'family_plan_title'.tr(),
      (true, _) =>
        '${'family_plan_title'.tr()} · ${'plan_n_months'.tr(namedArgs: {'count': '$months'})}',
      (false, 1) => Strings.monthlyPremium,
      (false, _) => Strings.nMothPremium(month: months),
    };
    return PlanModel(
      id: package.id,
      title: title,
      price: package.price,
      originalFee: package.hasReferralDiscount
          ? max(package.originalFee, package.fee)
          : package.originalFee,
      packageMonth: months,
      isMostPopular: package.isPopular,
    );
  }

  PlanModel? _pick(List<PlanModel> plans, int? id) =>
      plans.firstWhereOrNull((plan) => plan.id == id) ??
      plans.firstWhereOrNull((plan) => plan.isMostPopular) ??
      plans.firstOrNull;

  void _applyIsUzbekistan(bool isUzbekistan) {
    final iap = PaymentMethod(icon: Assets.icons.apple, code: 'Iap');
    final payme = PaymentMethod(icon: Assets.icons.payme, code: 'Payme');
    final click = PaymentMethod(icon: Assets.icons.click, code: 'Click');
    if (state.isFamily) {
      emit(
        state.copyWith(
          isUzbekistan: isUzbekistan,
          paymentMethods: isUzbekistan || kDebugMode ? [payme, click] : [],
        ),
      );
      _logPaywallViewed();
      return;
    }
    if (kDebugMode) {
      emit(
        state.copyWith(
          isUzbekistan: isUzbekistan,
          paymentMethods: [iap, click, payme],
        ),
      );
    } else if (isUzbekistan) {
      emit(
        state.copyWith(
          isUzbekistan: isUzbekistan,
          paymentMethods: [payme, click],
        ),
      );
    } else {
      emit(
        state.copyWith(
          isUzbekistan: isUzbekistan,
          paymentMethods: [iap],
          selectedPaymentMethod: iap,
        ),
      );
    }

    unawaited(_loadIapPrices());
    if (!state.isIap) _logPaywallViewed();
  }

  Future<void> _loadIapPrices() async {
    if (state.isFamily) return;
    if (_iapPricesRequested) return;
    if (state.plans.isEmpty) return;
    if (!state.paymentMethods.any((method) => method.code == 'Iap')) return;
    _iapPricesRequested = true;

    emit(state.copyWith(isLoadingIapPrices: true));
    final products = await getIt<RevenueCatService>().planProducts(state.plans);
    _iapProducts
      ..clear()
      ..addAll(products);
    emit(
      state.copyWith(
        isLoadingIapPrices: false,
        iapPrices: {
          for (final entry in products.entries)
            entry.key: entry.value.priceString,
        },
      ),
    );
    _ensureSelectedPlanIsPurchasable();
    _logPaywallViewed();
  }

  void _logUnmatchedPlans() {
    if (!state.isIap || state.isLoadingIapPrices || state.plans.isEmpty) return;

    final unmatched = state.plans
        .where((plan) => !state.iapPrices.containsKey(plan.id))
        .map((plan) => '${plan.id}("${plan.title}", ${plan.packageMonth}mo)')
        .toList();
    if (unmatched.isEmpty) return;

    getIt<Logger>().e(
      'IAP: ${unmatched.length} backend plan(s) have no store product and are '
      'hidden from the sheet: ${unmatched.join(', ')}. '
      'Store products resolved: ${state.iapPrices.keys.toList()}',
    );
  }

  void _ensureSelectedPlanIsPurchasable() {
    _logUnmatchedPlans();
    if (!state.isIap || state.isLoadingIapPrices) return;

    final selected = state.selectedPlan;
    if (selected != null && state.iapPrices.containsKey(selected.id)) return;

    final fallback = state.purchasablePlans.firstOrNull;
    if (fallback != null) emit(state.copyWith(selectedPlan: fallback));
  }

  Future<void> redeemOfferCode() async {
    try {
      final presented = await getIt<RevenueCatService>()
          .presentOfferCodeRedemption();
      _awaitingOfferCode = true;

      if (!presented) {
        _openPaymentUrl(_playRedeemUrl);
        return;
      }

      _awaitingExternalPayment = true;
      _startPaymentPolling();
    } catch (e) {
      publish(PremiumEffect.openPaymentUrlFailure(e.toString()));
    }
  }

  void selectPlan(PlanModel plan) {
    emit(state.copyWith(selectedPlan: plan));
    final price = _metaPriceFor(plan);
    if (price == null) return;
    final (value, currency) = price;
    unawaited(
      FacebookAnalyticsService.instance.logAddToCart(
        contentId: plan.id.toString(),
        contentType: _metaContentType,
        price: value,
        currency: currency,
      ),
    );
  }

  void selectPaymentMethod(PaymentMethod method) {
    emit(state.copyWith(selectedPaymentMethod: method));
    unawaited(
      FacebookAnalyticsService.instance.logAddPaymentInfo(success: true),
    );
  }

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
        id: plan.id,
        title: plan.title,
        price: plan.actualPrice ?? plan.price,
        originalFee: plan.originalFee,
        packageMonth: plan.packageMonth,
        isMostPopular: plan.isMostPopular,
      );
    }).toList();

    emit(
      state.copyWith(
        isGettingPromoCodeValue: false,
        promoCodeValue: null,
        plans: restoredPlans,
        selectedPlan: _pick(restoredPlans, state.selectedPlan?.id),
      ),
    );
  }

  Future<void> getPromoCodeValue(String code) async {
    if (code.trim().isEmpty) return restoreOriginalPrices();

    // A family-plan code isn't a discount: it turns Premium on outright.
    // People type whatever code they got into "Promo code", so accept it here.
    if (isFamilyCode(code)) {
      return _redeemFamilyCode(code.trim());
    }

    await _premiumRepo
        .getPromoCodeAmount(code: code)
        .handle(
          onStart: () => emit(state.copyWith(isGettingPromoCodeValue: true)),
          onData: (data) {
            if (data.id != null && data.amount != null) {
              final amount = data.sum;
              final discountedPlans = state.plans.map((plan) {
                final base = plan.actualPrice ?? plan.price;
                final discountedPrice = (base - amount).clamp(0, base);
                return PlanModel(
                  id: plan.id,
                  title: plan.title,
                  price: discountedPrice,
                  actualPrice: base,
                  originalFee: plan.originalFee,
                  packageMonth: plan.packageMonth,
                  isMostPopular: plan.isMostPopular,
                );
              }).toList();

              final newSelectedPlan = _pick(
                discountedPlans,
                state.selectedPlan?.id,
              );

              PaymentMethod? autoMethod = state.selectedPaymentMethod;
              if (autoMethod == null &&
                  (newSelectedPlan?.isFree ?? false) &&
                  state.paymentMethods.isNotEmpty) {
                autoMethod = state.paymentMethods.first;
              }

              emit(
                state.copyWith(
                  isGettingPromoCodeValue: false,
                  promoCodeValue: data,
                  plans: discountedPlans,
                  selectedPlan: newSelectedPlan,
                  selectedPaymentMethod: autoMethod,
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

  Future<void> _redeemFamilyCode(String code) async {
    emit(state.copyWith(isGettingPromoCodeValue: true));
    try {
      final result = await _premiumRepo.redeemFamilyCode(code);
      if (result.requiresTokenRefresh) {
        await getIt<TokenInterceptor>().refreshAndCheckPremium();
      }
      if (isClosed) return;
      emit(state.copyWith(isGettingPromoCodeValue: false));
      publish(PremiumEffect.familyCodeRedeemed(result.ownerName));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isGettingPromoCodeValue: false));
      publish(PremiumEffect.openPaymentUrlFailure(familyCodeErrorText(e)));
    }
  }

  Future<void> orderSubscription({bool? restore}) async {
    final isRestore = restore ?? false;
    final isIap = state.selectedPaymentMethod?.code == 'Iap';

    if (!isRestore) _logInitiateCheckout();

    final isFreePlan = state.selectedPlan?.isFree ?? false;
    final providerCode =
        state.selectedPaymentMethod?.code ??
        (isFreePlan && state.paymentMethods.isNotEmpty
            ? state.paymentMethods.first.code
            : '');

    await _premiumRepo
        .orderSubscription(
          provider: providerCode,
          plan:
              (state.isFamily
                      ? SubscriptionPlanType.family
                      : SubscriptionPlanType.premium)
                  .toApi(),
          orderMonth: state.selectedPlan?.id ?? -1,
          couponId: state.promoCodeValue?.id,
        )
        .handle(
          onStart: () => emit(
            state.copyWith(
              isOrderingSubscription: !isRestore,
              isRestoringPurchase: isRestore,
            ),
          ),
          onData: (link) async {
            emit(state.copyWith(paymentLink: link.paymentLink ?? ''));
            if (link.paymentRequired ?? true) {
              if (isIap) {
                await _openIap(state.selectedPlan!, restore: isRestore);
              } else {
                emit(
                  state.copyWith(
                    isOrderingSubscription: false,
                    isRestoringPurchase: false,
                  ),
                );
                _openPaymentUrl(link.paymentLink ?? '');
              }
            } else {
              emit(
                state.copyWith(
                  isOrderingSubscription: false,
                  isRestoringPurchase: false,
                ),
              );
              publish(const PremiumEffect.subscriptionSuccess());
            }
          },
          onError: (error) => emit(
            state.copyWith(
              isOrderingSubscription: false,
              isRestoringPurchase: false,
            ),
          ),
        );
  }

  Future<void> deleteOrder() async => _premiumRepo
      .deleteOrder(orderId: state.myOrders.first.id ?? -1)
      .handle(
        onStart: () => emit(state.copyWith(isDeletingOrder: true)),
        onData: (_) {
          _stopPaymentPolling();
          emit(state.copyWith(isDeletingOrder: false, isPaymentPending: false));
        },
        onError: (_) => emit(state.copyWith(isDeletingOrder: false)),
      );

  Future<void> getPaymentLink({bool? restore}) async {
    final isRestore = restore ?? false;
    if (!isRestore) _logInitiateCheckout();
    if (state.selectedPaymentMethod?.code == 'Iap') {
      final plan = state.selectedPlan;
      if (plan == null) return;
      emit(
        state.copyWith(
          isOrderingSubscription: !isRestore,
          isRestoringPurchase: isRestore,
        ),
      );
      await _openIap(plan, restore: isRestore);
      return;
    }
    await _premiumRepo
        .getPaymentLink(orderId: state.myOrders.first.id ?? -1)
        .handle(
          onStart: () => emit(state.copyWith(isGettingPaymentLink: true)),
          onData: (link) {
            emit(
              state.copyWith(isGettingPaymentLink: false, paymentLink: link),
            );
            _openPaymentUrl(link);
          },
          onError: (error) => emit(state.copyWith(isGettingPaymentLink: false)),
        );
  }

  Future<void> _openPaymentUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      _familyCodesBefore = state.isFamily ? await _familyCodesNow() : null;
      if (await canLaunchUrl(uri)) {
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          publish(
            PremiumEffect.openPaymentUrlFailure(
              Strings.couldNotLaunchPaymentUrl,
            ),
          );
          return;
        }
        _awaitingExternalPayment = true;
        _startPaymentPolling();
      } else {
        publish(
          PremiumEffect.openPaymentUrlFailure(Strings.couldNotLaunchPaymentUrl),
        );
      }
    } catch (e) {
      publish(PremiumEffect.openPaymentUrlFailure(e.toString()));
    }
  }

  void _startPaymentPolling() {
    _paymentPollTicks = 0;
    _paymentPollTimer?.cancel();
    _paymentPollTimer = Timer.periodic(_paymentPollInterval, (_) {
      _paymentPollTicks++;
      if (_paymentPollTicks > _paymentPollMaxTicks) {
        _stopPaymentPolling();
        return;
      }
      unawaited(_checkExternalPayment());
    });
  }

  void _stopPaymentPolling() {
    _paymentPollTimer?.cancel();
    _paymentPollTimer = null;
    _awaitingExternalPayment = false;
    _awaitingOfferCode = false;
  }

  Future<Set<String>?> _familyCodesNow() async {
    try {
      final coupons = await _premiumRepo.getMyCoupons();
      return coupons.map((coupon) => coupon.code).toSet();
    } catch (_) {
      return null;
    }
  }

  static FamilyCoupon? newFamilyCoupon(
    Set<String> before,
    List<FamilyCoupon> now,
  ) => now.firstWhereOrNull(
    (coupon) =>
        coupon.status == FamilyCodeStatus.active &&
        !before.contains(coupon.code),
  );

  Future<void> _checkExternalPayment() async {
    if (!_awaitingExternalPayment || _checkingExternalPayment) return;
    _checkingExternalPayment = true;

    try {
      final before = _familyCodesBefore;
      if (state.isFamily && before != null) {
        List<FamilyCoupon> coupons;
        try {
          coupons = await _premiumRepo.getMyCoupons();
        } catch (_) {
          return;
        }
        await getMyOrders();
        final issued = newFamilyCoupon(before, coupons);
        if (issued == null) return;
        issuedFamilyCoupon = issued;
        // The plan claim lives in the JWT — pick it up before celebrating.
        await getIt<TokenInterceptor>().refreshAndCheckPremium();
        _stopPaymentPolling();
        _familyCodesBefore = null;
        _logExternalPurchase();
        publish(const PremiumEffect.subscriptionSuccess());
        return;
      }

      if (_awaitingOfferCode &&
          await getIt<RevenueCatService>().hasActiveEntitlement()) {
        _stopPaymentPolling();
        await getMyOrders();
        publish(const PremiumEffect.subscriptionSuccess());
        return;
      }

      final premium = await getIt<TokenInterceptor>().refreshAndCheckPremium();
      await getMyOrders();

      if (premium) {
        _stopPaymentPolling();
        _logExternalPurchase();
        publish(const PremiumEffect.subscriptionSuccess());
      }
    } finally {
      _checkingExternalPayment = false;
    }
  }

  Future<void> _openIap(PlanModel plan, {bool restore = false}) async {
    try {
      final orders = await _premiumRepo.getMyOrders();
      final pendingOrder = orders.isNotEmpty
          ? orders.firstWhere(
              (e) => e.status?.trim().toLowerCase() == 'pending',
              orElse: () => orders.first,
            )
          : null;
      final purchased = await getIt<RevenueCatService>().purchase(
        plan,
        restore,
        pendingOrder,
      );
      if (purchased) {
        publish(PremiumEffect.subscriptionSuccess());
      }
    } catch (e) {
      publish(PremiumEffect.openPaymentUrlFailure(e.toString()));
    } finally {
      emit(
        state.copyWith(
          isOrderingSubscription: false,
          isRestoringPurchase: false,
        ),
      );
    }
  }

  static const String _metaContentType =
      FacebookAnalyticsService.contentTypeSubscription;

  static const String _localCurrency = 'UZS';

  (double, String)? _metaPriceFor(PlanModel plan) {
    if (state.isIap) {
      final product = _iapProducts[plan.id];
      if (product == null) return null;
      return (product.price, product.currencyCode);
    }
    return (plan.price.toDouble(), _localCurrency);
  }

  void _logPaywallViewed() {
    if (_paywallViewLogged) return;
    final plan = state.selectedPlan;
    if (plan == null) return;

    final price = _metaPriceFor(plan);
    if (price == null) return;
    _paywallViewLogged = true;

    final (value, currency) = price;
    unawaited(
      FacebookAnalyticsService.instance.logViewContent(
        contentId: plan.id.toString(),
        contentType: _metaContentType,
        currency: currency,
        valueToSum: value,
      ),
    );
  }

  void _logInitiateCheckout() {
    final plan = state.selectedPlan;
    if (plan == null) return;

    final price = _metaPriceFor(plan);
    if (price == null) return;
    final (value, currency) = price;
    unawaited(
      FacebookAnalyticsService.instance.logInitiateCheckout(
        contentId: plan.id.toString(),
        contentType: _metaContentType,
        currency: currency,
        valueToSum: value,
        paymentInfoAvailable: state.selectedPaymentMethod != null,
      ),
    );
  }

  void _logExternalPurchase() {
    final plan = state.selectedPlan;
    if (plan == null) return;

    final orderId = state.myOrders.firstOrNull?.id?.toString();
    if (orderId == null) return;

    final price = _metaPriceFor(plan);
    if (price == null) return;
    final (value, currency) = price;
    final parameters = <String, dynamic>{
      'plan_id': plan.id,
      'package_month': plan.packageMonth,
      'provider': state.selectedPaymentMethod?.code ?? 'unknown',
    };

    final meta = FacebookAnalyticsService.instance;
    unawaited(
      meta.logSubscribe(
        orderId: orderId,
        value: value,
        currency: currency,
        parameters: parameters,
      ),
    );
    unawaited(
      meta.logPurchase(
        contentId: plan.id.toString(),
        contentType: _metaContentType,
        currency: currency,
        valueToSum: value,
        transactionId: orderId,
        parameters: parameters,
      ),
    );
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _paymentPollTimer?.cancel();
    _countrySubscription?.cancel();
    return super.close();
  }
}
