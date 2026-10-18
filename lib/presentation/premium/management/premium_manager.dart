import 'dart:async';
import 'dart:math';

import 'package:calora/common/di/injection.dart';
import 'package:calora/common/enums/subscription_plan_type.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/service/facebook_analytics_service.dart';
import 'package:calora/common/service/premium_service.dart';
import 'package:calora/common/service/revenuecat_service.dart';
import 'package:calora/domain/model/premium/family_code.dart';
import 'package:calora/domain/model/premium/family_coupon.dart';
import 'package:calora/domain/model/premium/my_subscription.dart';
import 'package:calora/domain/model/premium/my_subscription_order_model.dart';
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
  PremiumManager(
    this._premiumRepo,
    this._commonRepo,
    this._premium,
    this._revenueCat,
  ) : super(const PremiumState()) {
    WidgetsBinding.instance.addObserver(this);
  }

  final PremiumRepo _premiumRepo;
  final CommonRepo _commonRepo;
  final PremiumService _premium;
  final RevenueCatService _revenueCat;

  static const _paymentPollInterval = Duration(seconds: 5);
  static const _paymentPollTicks = 24;
  static const _playRedeemUrl = 'https://play.google.com/redeem';
  static const _metaContentType =
      FacebookAnalyticsService.contentTypeSubscription;
  static const _localCurrency = 'UZS';

  StreamSubscription<bool>? _countrySubscription;
  Timer? _paymentPollTimer;
  bool _awaitingExternalPayment = false;
  bool _checkingExternalPayment = false;
  bool _awaitingOfferCode = false;
  Set<String>? _familyCodesBefore;
  MySubscription? _subscriptionBefore;
  bool _iapPricesRequested = false;
  final Map<int, StoreProduct> _iapProducts = {};
  bool _paywallViewLogged = false;

  FamilyCoupon? issuedFamilyCoupon;

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (!_awaitingExternalPayment) return;
    if (lifecycleState == AppLifecycleState.resumed) {
      unawaited(_checkExternalPayment());
      _startPaymentPolling();
    } else if (lifecycleState == AppLifecycleState.paused) {
      _stopPaymentPolling();
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
    final products = await _revenueCat.planProducts(state.plans);
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
      final presented = await _revenueCat.presentOfferCodeRedemption();
      _awaitingOfferCode = true;
      if (!presented) {
        await _openPaymentUrl(_playRedeemUrl);
        return;
      }
      _subscriptionBefore = await _currentSubscription();
      _awaitingExternalPayment = true;
      _startPaymentPolling();
    } catch (e) {
      publish(PremiumEffect.openPaymentUrlFailure(_errorText(e)));
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

  Future<void> getMyOrders() => _premiumRepo.getMyOrders().handle(
    onStart: () => emit(state.copyWith(isGettingOrders: true)),
    onData: (orders) {
      final pending = orders.pending;
      final pendingMethod = state.paymentMethods.firstWhereOrNull(
        (method) => method.code == pending?.provider,
      );
      emit(
        state.copyWith(
          isGettingOrders: false,
          myOrders: orders,
          isPaymentPending: pending != null,
          selectedPaymentMethod: pendingMethod ?? state.selectedPaymentMethod,
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
      await _premium.sync(force: true);
      if (isClosed) return;
      emit(state.copyWith(isGettingPromoCodeValue: false));
      publish(PremiumEffect.familyCodeRedeemed(result.ownerName));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isGettingPromoCodeValue: false));
      publish(PremiumEffect.openPaymentUrlFailure(familyCodeErrorText(e)));
    }
  }

  Future<void> orderSubscription() async {
    final plan = state.selectedPlan;
    if (plan == null) return;
    _logInitiateCheckout();

    final method = state.selectedPaymentMethod;
    final provider =
        method?.code ??
        (plan.isFree ? state.paymentMethods.firstOrNull?.code : null) ??
        '';

    await _premiumRepo
        .orderSubscription(
          provider: provider,
          plan:
              (state.isFamily
                      ? SubscriptionPlanType.family
                      : SubscriptionPlanType.premium)
                  .toApi(),
          orderMonth: plan.id,
          couponId: state.promoCodeValue?.id,
        )
        .handle(
          onStart: () => emit(state.copyWith(isOrderingSubscription: true)),
          onData: (response) async {
            emit(state.copyWith(paymentLink: response.paymentLink ?? ''));
            if (!(response.paymentRequired ?? true)) {
              await _premium.markPurchased();
              emit(state.copyWith(isOrderingSubscription: false));
              publish(const PremiumEffect.subscriptionSuccess());
              return;
            }
            if (method?.code == 'Iap') {
              await _openIap(plan);
              return;
            }
            emit(state.copyWith(isOrderingSubscription: false));
            await _openPaymentUrl(response.paymentLink ?? '');
          },
          onError: (_) => emit(state.copyWith(isOrderingSubscription: false)),
        );
  }

  Future<void> continuePurchase() async {
    _logInitiateCheckout();
    if (state.isIap) {
      final plan = state.selectedPlan;
      if (plan != null) await _openIap(plan);
      return;
    }

    final orderId = state.pendingOrder?.id;
    if (orderId == null) return;
    await _premiumRepo
        .getPaymentLink(orderId: orderId)
        .handle(
          onStart: () => emit(state.copyWith(isGettingPaymentLink: true)),
          onData: (link) {
            emit(
              state.copyWith(isGettingPaymentLink: false, paymentLink: link),
            );
            unawaited(_openPaymentUrl(link));
          },
          onError: (_) => emit(state.copyWith(isGettingPaymentLink: false)),
        );
  }

  Future<void> restorePurchase() async {
    emit(state.copyWith(isRestoringPurchase: true));
    try {
      if (!await _revenueCat.restore()) return;
      await _premium.markPurchased();
      publish(const PremiumEffect.subscriptionSuccess());
    } catch (e) {
      publish(PremiumEffect.openPaymentUrlFailure(_errorText(e)));
    } finally {
      emit(state.copyWith(isRestoringPurchase: false));
    }
  }

  Future<void> deleteOrder() async {
    final orderId = state.pendingOrder?.id;
    if (orderId == null) return;
    await _premiumRepo
        .deleteOrder(orderId: orderId)
        .handle(
          onStart: () => emit(state.copyWith(isDeletingOrder: true)),
          onData: (_) {
            _finishExternalPayment();
            final orders = state.myOrders
                .where((order) => order.id != orderId)
                .toList();
            emit(
              state.copyWith(
                isDeletingOrder: false,
                isPaymentPending: orders.pending != null,
                myOrders: orders,
              ),
            );
          },
          onError: (_) => emit(state.copyWith(isDeletingOrder: false)),
        );
  }

  Future<void> _openIap(PlanModel plan) async {
    emit(state.copyWith(isOrderingSubscription: true));
    try {
      final order = (await _premiumRepo.getMyOrders()).pending;
      if (!await _revenueCat.purchase(plan, order: order)) return;
      await _premium.markPurchased();
      publish(const PremiumEffect.subscriptionSuccess());
    } catch (e) {
      publish(PremiumEffect.openPaymentUrlFailure(_errorText(e)));
    } finally {
      emit(state.copyWith(isOrderingSubscription: false));
    }
  }

  Future<void> _openPaymentUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      publish(
        PremiumEffect.openPaymentUrlFailure(Strings.couldNotLaunchPaymentUrl),
      );
      return;
    }

    if (state.isFamily) {
      _familyCodesBefore = await _familyCodesNow();
    } else {
      _subscriptionBefore = await _currentSubscription();
    }
    var launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e, st) {
      getIt<Logger>().e('Payment URL launch failed: $e', stackTrace: st);
    }
    if (!launched) {
      publish(
        PremiumEffect.openPaymentUrlFailure(Strings.couldNotLaunchPaymentUrl),
      );
      return;
    }

    _awaitingExternalPayment = true;
    _startPaymentPolling();
  }

  void _startPaymentPolling() {
    _paymentPollTimer?.cancel();
    _paymentPollTimer = Timer.periodic(_paymentPollInterval, (timer) {
      if (timer.tick > _paymentPollTicks) {
        timer.cancel();
        return;
      }
      unawaited(_checkExternalPayment());
    });
  }

  void _stopPaymentPolling() {
    _paymentPollTimer?.cancel();
    _paymentPollTimer = null;
  }

  void _finishExternalPayment() {
    _stopPaymentPolling();
    _awaitingExternalPayment = false;
    _awaitingOfferCode = false;
    _familyCodesBefore = null;
    _subscriptionBefore = null;
  }

  Future<Set<String>?> _familyCodesNow() async {
    try {
      final coupons = await _premiumRepo.getMyCoupons();
      return coupons.map((coupon) => coupon.code).toSet();
    } catch (_) {
      return null;
    }
  }

  Future<MySubscription?> _currentSubscription() async {
    try {
      return await _premiumRepo.getMySubscription();
    } catch (_) {
      return null;
    }
  }

  static bool isExtended(MySubscription before, MySubscription after) {
    final beforeEnd = before.endsAt;
    final afterEnd = after.endsAt;
    return after.isPremium &&
        beforeEnd != null &&
        afterEnd != null &&
        afterEnd.isAfter(beforeEnd);
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
      if (!await _externalPaymentDone() || !_awaitingExternalPayment) return;
      _finishExternalPayment();
      _logExternalPurchase();
      publish(const PremiumEffect.subscriptionSuccess());
    } finally {
      _checkingExternalPayment = false;
    }
  }

  Future<bool> _externalPaymentDone() async {
    if (_awaitingOfferCode && await _revenueCat.hasActiveEntitlement()) {
      await _premium.markPurchased();
      return true;
    }

    final before = _familyCodesBefore;
    if (state.isFamily && before != null) {
      final List<FamilyCoupon> coupons;
      try {
        coupons = await _premiumRepo.getMyCoupons();
      } catch (_) {
        return false;
      }
      final issued = newFamilyCoupon(before, coupons);
      if (issued == null) return false;
      issuedFamilyCoupon = issued;
      await _premium.sync(force: true);
      return true;
    }

    final subscriptionBefore = _subscriptionBefore;
    if (subscriptionBefore == null || !subscriptionBefore.isPremium) {
      return _premium.sync(force: true);
    }
    final subscription = await _currentSubscription();
    if (subscription == null || !isExtended(subscriptionBefore, subscription)) {
      return false;
    }
    await _premium.sync(force: true);
    return true;
  }

  static String _errorText(Object error) =>
      error is IapException ? error.message : Strings.errorViewMessage;

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

    final orderId = (state.pendingOrder ?? state.myOrders.newest)?.id
        ?.toString();
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
