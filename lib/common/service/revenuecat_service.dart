import 'dart:io';

import 'package:calora/common/base/profile_store.dart';
import 'package:calora/common/di/injection.dart';
import 'package:calora/common/widgets/display/display.dart';
import 'package:calora/domain/model/premium/my_subscription_order_model.dart';
import 'package:calora/domain/model/profile/profile_request.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/premium/management/premium_management.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class IapException implements Exception {
  final String message;

  const IapException(this.message);

  @override
  String toString() => message;
}

@lazySingleton
class RevenueCatService {
  final ProfileStore _store;

  RevenueCatService(this._store);

  static const String _entitlementId = 'Calora Premium';

  /// Legacy convention: the store product identifier ends with the
  /// backend plan id (`product_4` ⇒ plan 4). iOS uses `_`, Android `-`.
  static String get _idSeparator => Platform.isAndroid ? '-' : '_';

  /// Months covered by a package, or null for package types that don't
  /// express a subscription duration (lifetime, weekly, custom).
  static int? _packageMonths(Package package) => switch (package.packageType) {
    PackageType.monthly => 1,
    PackageType.twoMonth => 2,
    PackageType.threeMonth => 3,
    PackageType.sixMonth => 6,
    PackageType.annual => 12,
    _ => null,
  };

  /// Resolves the store package backing a backend plan. Single source of
  /// truth: both pricing and purchasing go through it, so a plan can
  /// never display a price it then fails to charge.
  ///
  /// Matches on **duration** first — a 12-month backend plan maps to the
  /// offering's annual package. Store product identifiers are immutable
  /// once created in App Store Connect, so they cannot be renamed to
  /// track backend plan ids; duration is the only attribute both systems
  /// independently agree on.
  ///
  /// Falls back to the legacy id-suffix convention so any plan that
  /// resolves today keeps resolving.
  Package? _packageForPlan(Offering offering, PlanModel plan) {
    final byDuration = offering.availablePackages.firstWhereOrNull(
      (package) => _packageMonths(package) == plan.packageMonth,
    );
    if (byDuration != null) return byDuration;

    final suffix = '$_idSeparator${plan.id}';
    return offering.availablePackages.firstWhereOrNull(
      (package) => package.storeProduct.identifier.endsWith(suffix),
    );
  }

  Future<Offering?> _currentOffering() async {
    final offerings = await Purchases.getOfferings();
    return offerings.current ??
        offerings.all['default'] ??
        offerings.all.values.firstOrNull;
  }

  Future<void> init() async {
    if (kIsWeb) return;
    await Purchases.setLogLevel(
      kDebugMode ? LogLevel.debug : LogLevel.info,
    );

    final key = Platform.isAndroid
        ? 'goog_GChcNuFzhSLLuenQOOdpdaatuJQ'
        : 'appl_VZdWGZmrtjFMtQWQfdlEbRYulSJ';
    final configuration = PurchasesConfiguration(key);

    final profile = await _store.getProfile();

    if (profile.userId != null) {
      configuration.appUserID = profile.userId!.toString();
    }

    await Purchases.configure(configuration);

    if (profile.userId != null) {
      await Purchases.setEmail(profile.email ?? '');
      await Purchases.setDisplayName(profile.name ?? '');
    }
  }

  Future<String?> storefrontCountryCode() async {
    if (kIsWeb) return null;
    try {
      final storefront = await Purchases.storefront;
      return storefront?.countryCode.toUpperCase();
    } catch (e, st) {
      getIt<Logger>().e('Storefront lookup failed: $e', stackTrace: st);
      return null;
    }
  }

  /// Store products for the current offering, keyed by backend plan id.
  ///
  /// [StoreProduct.priceString] is the **only** price safe to show on the
  /// IAP flow: it is what the store will actually charge, already
  /// formatted for the user's storefront currency and locale. The backend
  /// `fee` is a UZS amount for Payme/Click and has no relationship to it.
  ///
  /// Returns an empty map on any failure — callers treat a missing entry
  /// as "not purchasable through IAP" rather than falling back to a price
  /// the store won't honour.
  Future<Map<int, StoreProduct>> planProducts(List<PlanModel> plans) async {
    if (kIsWeb) return const {};
    try {
      final offering = await _currentOffering();
      if (offering == null) {
        getIt<Logger>().e('IAP: no offerings available');
        return const {};
      }

      final products = <int, StoreProduct>{};
      for (final plan in plans) {
        final package = _packageForPlan(offering, plan);
        if (package != null) products[plan.id] = package.storeProduct;
      }

      getIt<Logger>().i(
        'IAP offering "${offering.identifier}" packages: '
        '${offering.availablePackages.map((e) => '${e.packageType.name}'
            '/${e.storeProduct.identifier}=${e.storeProduct.priceString}').join(', ')}'
        ' → matched plans ${products.keys.toList()}',
      );
      return products;
    } catch (e, st) {
      getIt<Logger>().e('IAP price lookup failed: $e', stackTrace: st);
      return const {};
    }
  }

  /// Presents Apple's native offer-code redemption sheet.
  ///
  /// Returns `false` when the platform has no in-app redemption sheet, so
  /// the caller can route to the store's own redemption page instead.
  /// Android is such a case: `presentCodeRedemptionSheet` is a documented
  /// iOS-only call and the plugin's Android side handles it as a silent
  /// no-op, so calling it there would leave the button doing nothing.
  ///
  /// Fire-and-forget by design: the underlying call returns as soon as the
  /// sheet is *presented*, not when redemption finishes, and the purchase
  /// itself completes in StoreKit outside the app. Callers must watch for
  /// the resulting entitlement separately — see [hasActiveEntitlement].
  Future<bool> presentOfferCodeRedemption() async {
    if (kIsWeb || !Platform.isIOS) return false;
    await Purchases.presentCodeRedemptionSheet();
    return true;
  }

  /// Uncached entitlement read, for confirming a purchase that completed
  /// outside the app (offer-code redemption). The cache is invalidated
  /// first because RevenueCat would otherwise keep serving the pre-
  /// redemption CustomerInfo for the rest of its TTL.
  Future<bool> hasActiveEntitlement() async {
    if (kIsWeb) return false;
    try {
      await Purchases.invalidateCustomerInfoCache();
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[_entitlementId]?.isActive == true;
    } catch (e, st) {
      getIt<Logger>().e('Entitlement check failed: $e', stackTrace: st);
      return false;
    }
  }

  Future<void> login(ProfileRequest? user) async {
    if (user == null) return;
    await Purchases.logIn(user.userId!.toString());
    await Purchases.setEmail(user.email ?? '');
    await Purchases.setDisplayName(user.name ?? '');
  }

  Future<bool> purchase(
    PlanModel plan, [
    bool restore = false,
    MySubscriptionOrderModel? order,
  ]) async {
    if (kIsWeb) {
      throw IapException(Strings.errorViewMessage);
    }
    try {
      await Purchases.setAttributes({
        'order_id': order?.id?.toString() ?? '',
      });
      await Purchases.syncAttributesAndOfferingsIfNeeded();

      if (restore) {
        final customerInfo = await Purchases.restorePurchases();
        final isActive =
            customerInfo.entitlements.all[_entitlementId]?.isActive == true;
        if (!isActive) {
          getIt<Display>().info(description: 'No previous purchase');
        }
        return isActive;
      }

      final offering = await _currentOffering();

      if (offering == null) {
        getIt<Logger>().e('IAP: no offerings available');
        throw IapException(Strings.errorViewMessage);
      }

      final packages = offering.availablePackages;
      if (packages.isEmpty) {
        getIt<Logger>().e('IAP: offering "${offering.identifier}" has no packages');
        throw IapException(Strings.errorViewMessage);
      }

      final package = _packageForPlan(offering, plan);
      if (package == null) {
        getIt<Logger>().e(
          'IAP: no package for plan ${plan.id} (${plan.packageMonth}mo) among '
          '${packages.map((e) => '${e.packageType.name}/${e.storeProduct.identifier}').toList()}',
        );
        throw IapException(Strings.errorViewMessage);
      }

      final result = await Purchases.purchase(PurchaseParams.package(package));
      return result.customerInfo.entitlements.all[_entitlementId]?.isActive ==
          true;
    } on PlatformException catch (e, st) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      getIt<Logger>().e('IAP PlatformException $errorCode: $e', stackTrace: st);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        return false;
      }
      throw IapException(Strings.errorViewMessage);
    }
  }
}
