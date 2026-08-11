import 'dart:async';

import 'package:calora/common/di/injection.dart';
import 'package:calora/common/di/network/interceptor/token_interceptor.dart';
import 'package:calora/common/enums/subscription_plan_type.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/service/revenuecat_service.dart';
import 'package:calora/domain/repo/common/common_repo.dart';
import 'package:calora/domain/repo/premium/premium_repo.dart';
import 'package:calora/presentation/premium/management/premium_management.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:management/management.dart';
import 'package:url_launcher/url_launcher.dart';

@injectable
class PremiumManager extends Manager<PremiumState, PremiumEffect>
    with WidgetsBindingObserver {
  final PremiumRepo _premiumRepo;
  final CommonRepo _commonRepo;

  StreamSubscription<bool>? _countrySubscription;

  // ── External-payment (Click/Payme) result watching ──────────────────
  // Click/Payme open externally and complete via a backend webhook, so
  // the app must detect completion itself (on app-resume + a foreground
  // backup poll) and refresh the premium state — otherwise the UI only
  // updates after a manual app restart.
  bool _awaitingExternalPayment = false;
  Timer? _paymentPollTimer;
  int _paymentPollTicks = 0;
  static const Duration _paymentPollInterval = Duration(seconds: 5);
  static const int _paymentPollMaxTicks = 24; // ~2 min foreground backstop

  /// Set while an Apple offer-code redemption is outstanding, so
  /// [_checkExternalPayment] also consults RevenueCat directly — StoreKit
  /// knows about the redemption before our backend webhook does.
  bool _awaitingOfferCode = false;

  /// Google Play has no in-app redemption sheet; codes are entered in the
  /// Play Store itself.
  static const String _playRedeemUrl = 'https://play.google.com/redeem';

  bool _iapPricesRequested = false;

  PremiumManager(this._premiumRepo, this._commonRepo)
    : super(const PremiumState()) {
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    // Primary trigger: user returns from the Click/Payme app/page.
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

  void _applyIsUzbekistan(bool isUzbekistan) {
    final iap = PaymentMethod(icon: Assets.icons.apple, code: 'Iap');
    final payme = PaymentMethod(icon: Assets.icons.payme, code: 'Payme');
    final click = PaymentMethod(icon: Assets.icons.click, code: 'Click');
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

  /// Pulls store-localized prices for the IAP flow.
  ///
  /// These fully replace the backend UZS fees on that flow: App Review
  /// guideline 2.3.1 requires the displayed price to be what the store
  /// actually charges, and the two numbers are unrelated.
  ///
  /// Runs once per manager — `_applyIsUzbekistan` fires twice (cache then
  /// network) and the offering doesn't change in between.
  Future<void> _loadIapPrices() async {
    if (_iapPricesRequested) return;
    // Matching is per-plan now, so plans and payment methods both have to
    // be in before this can run. Whichever arrives last triggers it.
    if (state.plans.isEmpty) return;
    if (!state.paymentMethods.any((method) => method.code == 'Iap')) return;
    _iapPricesRequested = true;

    emit(state.copyWith(isLoadingIapPrices: true));
    final products = await getIt<RevenueCatService>().planProducts(state.plans);
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
  }

  /// Keeps [PremiumState.selectedPlan] pointing at something the user can
  /// actually buy. On IAP a plan with no store product is hidden by the
  /// sheet and would throw in `RevenueCatService.purchase`, so if the
  /// pre-selected "most popular" plan isn't backed by one, fall through to
  /// the first plan that is.
  /// Reports plans hidden from the IAP sheet because no store product
  /// carries their id. Logged rather than silently dropped: a plan
  /// vanishing from the sheet otherwise looks like a UI bug, when it
  /// really means the product is missing from the RevenueCat offering or
  /// its identifier suffix doesn't match the backend plan id.
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

  /// Promo-code entry point for the IAP flow.
  ///
  /// Apple offer codes are redeemed in a native StoreKit sheet and are a
  /// completely separate system from the backend coupon endpoint — a
  /// backend coupon cannot discount an App Store price, so the two never
  /// mix. Redemption completes outside the app, so this reuses the same
  /// resume + poll machinery as Click/Payme to notice the result.
  Future<void> redeemOfferCode() async {
    try {
      final presented = await getIt<RevenueCatService>()
          .presentOfferCodeRedemption();
      _awaitingOfferCode = true;

      if (!presented) {
        // Android (and iOS < 14): no in-app sheet, redeem in the store.
        // `_openPaymentUrl` starts the resume + poll watch itself.
        _openPaymentUrl(_playRedeemUrl);
        return;
      }

      _awaitingExternalPayment = true;
      _startPaymentPolling();
    } catch (e) {
      publish(PremiumEffect.openPaymentUrlFailure(e.toString()));
    }
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
                id: e.id ?? 0,
                title: Strings.monthlyPremium,
                price: e.fee ?? 0,
                originalFee: e.originalFee ?? 0,
                packageMonth: e.duration ?? 0,
                isMostPopular: e.isPopular ?? false,
              );
            }
            return PlanModel(
              id: e.id ?? 0,
              title: Strings.nMothPremium(month: e.duration ?? 0),
              price: e.fee ?? 0,
              originalFee: e.originalFee ?? 0,
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
          // IAP prices are matched per-plan, so they can only be fetched
          // once plans exist; this is the other half of the rendezvous
          // in `_applyIsUzbekistan`.
          unawaited(_loadIapPrices());
          _ensureSelectedPlanIsPurchasable();
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

    await _premiumRepo
        .getPromoCodeAmount(code: code)
        .handle(
          onStart: () => emit(state.copyWith(isGettingPromoCodeValue: true)),
          onData: (data) {
            if (data.id != null && data.amount != null) {
              // Coupon `amount` is returned in tiyin (1 UZS = 100
              // tiyin) while plan `fee` is in UZS — convert before
              // subtracting. The clamp below floors the visible
              // payable amount at 0 for "100% off" coupons; in that
              // case the order POST replies `paymentRequired: false`
              // and the success flow runs without hitting Payme / Click.
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

              // When the promo zeroes-out the selected plan and the
              // user hasn't picked a method, auto-pick the first one
              // so the order POST still has a valid `provider` field —
              // backend will then reply `paymentRequired: false` and
              // the existing success path takes over.
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

  Future<void> orderSubscription({bool? restore}) async {
    final isRestore = restore ?? false;
    final isIap = state.selectedPaymentMethod?.code == 'Iap';

    // Free-plan defense-in-depth: when a 100% promo is applied the UI
    // hides the payment picker, but the order POST still needs a
    // non-empty `provider`. If `getPromoCodeValue` didn't get to
    // auto-select one (e.g. promo applied before plans/methods loaded),
    // fall back to the first available method here. The backend will
    // still reply `paymentRequired: false` so the value is effectively
    // ignored — we just need the field to validate.
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
          // User abandoned the pending order — stop watching for a result.
          _stopPaymentPolling();
          emit(state.copyWith(isDeletingOrder: false, isPaymentPending: false));
        },
        onError: (_) => emit(state.copyWith(isDeletingOrder: false)),
      );

  Future<void> getPaymentLink({bool? restore}) async {
    final isRestore = restore ?? false;
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
      if (await canLaunchUrl(uri)) {
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          publish(
            PremiumEffect.openPaymentUrlFailure(
              Strings.couldNotLaunchPaymentUrl,
            ),
          );
          return;
        }
        // Click/Payme is now open externally. The payment completes via a
        // backend webhook, so start watching for the result — on
        // app-resume (primary) and a foreground backup poll — and flip the
        // UI to premium without requiring an app restart.
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

  /// Authoritative check after an external payment: force a token refresh
  /// and read the new `plan` claim. The Click/Payme webhook updates the
  /// subscription server-side; once it lands, the refreshed token is
  /// premium and `_commonStore.isUserPremium` flips — which the whole app
  /// watches reactively. We also refresh the sheet's order/pending state.
  Future<void> _checkExternalPayment() async {
    if (!_awaitingExternalPayment) return;

    // An offer code is redeemed entirely inside StoreKit, so RevenueCat
    // reflects it before the backend webhook lands. Check the entitlement
    // first so the UI doesn't sit spinning through the whole poll window.
    if (_awaitingOfferCode &&
        await getIt<RevenueCatService>().hasActiveEntitlement()) {
      _stopPaymentPolling();
      await getMyOrders();
      publish(const PremiumEffect.subscriptionSuccess());
      return;
    }

    final premium = await getIt<TokenInterceptor>().refreshAndCheckPremium();
    await getMyOrders(); // keep the pending/plan UI in sync either way

    if (premium) {
      _stopPaymentPolling();
      publish(const PremiumEffect.subscriptionSuccess());
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

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _paymentPollTimer?.cancel();
    _countrySubscription?.cancel();
    return super.close();
  }
}
