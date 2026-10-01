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

  static const String _playRedeemUrl = 'https://play.google.com/redeem';

  bool _iapPricesRequested = false;

  final Map<int, StoreProduct> _iapProducts = {};
  bool _paywallViewLogged = false;

  PremiumManager(this._premiumRepo, this._commonRepo)
    : super(const PremiumState()) {
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed &&
        _awaitingExternalPayment) {
      unawaited(_checkExternalPayment());
    }
  }

  void _init() {
    _countrySubscription = _commonRepo.getIsUzbekistan().cacheAndNetwork.listen(
      _applyIsUzbekistan,
      onError: (e, st) => getIt<Logger>().e(e.toString(), stackTrace: st),
    );
    getPremiumPlans();
    getMyOrders();
  }

  /// Package to preselect (picked on the tariffs page) instead of the
  /// "best offer" one.
  int? _preferredPlanId;

  void preferPlan(int? planId) {
    _preferredPlanId = planId;
    final match = state.plans.firstWhereOrNull((plan) => plan.id == planId);
    if (match != null) emit(state.copyWith(selectedPlan: match));
  }

  /// Switches the sheet to the family plan (two people). Called right after
  /// the manager is created, so the regular plans requested by `_init` are
  /// dropped when they land (see [getPremiumPlans]).
  void useFamilyPlan() {
    if (state.isFamily) return;
    emit(
      state.copyWith(
        isFamily: true,
        plans: const [],
        selectedPlan: null,
        paymentMethods: _withoutStore(state.paymentMethods),
        selectedPaymentMethod: state.selectedPaymentMethod?.code == 'Iap'
            ? null
            : state.selectedPaymentMethod,
      ),
    );
    getPremiumPlans();
  }

  /// The stores have no family product (and the backend refuses an IAP
  /// family order), so the family plan is sold through Payme / Click only.
  List<PaymentMethod> _withoutStore(List<PaymentMethod> methods) =>
      methods.where((method) => method.code != 'Iap').toList();

  void _applyIsUzbekistan(bool isUzbekistan) {
    final iap = PaymentMethod(icon: Assets.icons.apple, code: 'Iap');
    final payme = PaymentMethod(icon: Assets.icons.payme, code: 'Payme');
    final click = PaymentMethod(icon: Assets.icons.click, code: 'Click');
    if (state.isFamily) {
      emit(
        state.copyWith(
          isUzbekistan: isUzbekistan,
          paymentMethods: isUzbekistan || kDebugMode ? [payme, click] : [],
          selectedPaymentMethod: state.selectedPaymentMethod?.code == 'Iap'
              ? null
              : state.selectedPaymentMethod,
        ),
      );
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

  Future<void> getPremiumPlans() async {
    final family = state.isFamily;
    await _premiumRepo.getPremiumPlans(family: family).handle(
        onStart: () => emit(state.copyWith(isGettingPremiumPlans: true)),
        onData: (data) {
          // The sheet switched between regular and family meanwhile.
          if (family != state.isFamily) return;
          // A backend that ignores `family=true` returns the regular list —
          // never sell one of those as the family plan.
          final packages = family
              ? data.where((e) => e.isFamily ?? false).toList()
              : data;
          final plans = packages.map((e) {
            // Referral discount: the backend charges `discountedFee` on
            // Payme / Click, so that is the price shown; the full fee is
            // crossed out. IAP ignores it (store prices come from Apple / Google).
            final discounted = (e.referralDiscountPercent ?? 0) > 0;
            final fee = e.fee ?? 0;
            final price = discounted ? (e.discountedFee ?? fee) : fee;
            final originalFee = discounted
                ? max(e.originalFee ?? 0, fee)
                : e.originalFee ?? 0;
            if (e.isFamily ?? false) {
              return PlanModel(
                id: e.id ?? 0,
                title: 'family_plan_title'.tr(),
                price: price,
                originalFee: originalFee,
                packageMonth: e.duration ?? 0,
                isMostPopular: e.isPopular ?? false,
              );
            }
            if (e.duration == 1) {
              return PlanModel(
                id: e.id ?? 0,
                title: Strings.monthlyPremium,
                price: price,
                originalFee: originalFee,
                packageMonth: e.duration ?? 0,
                isMostPopular: e.isPopular ?? false,
              );
            }
            return PlanModel(
              id: e.id ?? 0,
              title: Strings.nMothPremium(month: e.duration ?? 0),
              price: price,
              originalFee: originalFee,
              packageMonth: e.duration ?? 0,
              isMostPopular: e.isPopular ?? false,
            );
          }).toList();
          final referralDiscountPercent = packages
              .map((e) => e.referralDiscountPercent ?? 0)
              .fold(0, max);

          PlanModel? initialPlan = plans.firstWhereOrNull(
            (plan) => plan.id == _preferredPlanId,
          );
          if (initialPlan == null) {
            try {
              initialPlan = plans.firstWhere((plan) => plan.isMostPopular);
            } catch (e) {
              initialPlan = plans.isNotEmpty ? plans.first : null;
            }
          }
          emit(
            state.copyWith(
              isGettingPremiumPlans: false,
              plans: plans,
              selectedPlan: initialPlan,
              referralDiscountPercent: referralDiscountPercent,
            ),
          );
          unawaited(_loadIapPrices());
          _ensureSelectedPlanIsPurchasable();
          _logPaywallViewed();
        },
        onError: (error) {
          if (family != state.isFamily) return;
          emit(state.copyWith(isGettingPremiumPlans: false));
        },
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

    // A family-plan code isn't a discount: it turns Premium on outright.
    // People type whatever code they got into "Promo code", so accept it here.
    if (code.trim().toUpperCase().startsWith(familyCodePrefix)) {
      return _redeemFamilyCode(code.trim());
    }

    await _premiumRepo
        .getPromoCodeAmount(code: code)
        .handle(
          onStart: () => emit(state.copyWith(isGettingPromoCodeValue: true)),
          onData: (data) {
            if (data.id != null && data.amount != null) {
              final amount = (data.amount ?? 0) ~/ 100;
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

  static const String familyCodePrefix = 'FAMILY-';

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
          plan: SubscriptionPlanType.premium.toApi(),
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

  /// Codes the user already has, or null when they can't be read.
  Future<Set<String>?> _familyCodesNow() async {
    try {
      final codes = await _premiumRepo.getFamilyCodes();
      return codes.map((code) => code.code).toSet();
    } catch (_) {
      return null;
    }
  }

  /// The family payment went through: the backend issues the second
  /// person's code together with the subscription, so a fresh active code
  /// is the proof.
  static bool familyCodeIssued(Set<String> before, List<FamilyCode> now) =>
      now.any(
        (code) =>
            code.status == FamilyCodeStatus.active &&
            !before.contains(code.code),
      );

  Future<void> _checkExternalPayment() async {
    if (!_awaitingExternalPayment || _checkingExternalPayment) return;
    _checkingExternalPayment = true;

    try {
      final before = _familyCodesBefore;
      if (state.isFamily && before != null) {
        List<FamilyCode> codes;
        try {
          codes = await _premiumRepo.getFamilyCodes();
        } catch (_) {
          return; // try again on the next tick
        }
        await getMyOrders();
        if (!familyCodeIssued(before, codes)) return;
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
