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
            customerInfo.entitlements.all['Calora Premium']?.isActive == true;
        if (!isActive) {
          getIt<Display>().info(description: 'No previous purchase');
        }
        return isActive;
      }

      final offerings = await Purchases.getOfferings();
      final offering = offerings.current ??
          offerings.all['default'] ??
          offerings.all.values.firstOrNull;

      if (offering == null) {
        getIt<Logger>().e('IAP: no offerings available');
        throw IapException(Strings.errorViewMessage);
      }

      final packages = offering.availablePackages;
      if (packages.isEmpty) {
        getIt<Logger>().e('IAP: offering "${offering.identifier}" has no packages');
        throw IapException(Strings.errorViewMessage);
      }

      final suffix = '${Platform.isAndroid ? '-' : '_'}${plan.id}';
      final package = packages.firstWhereOrNull(
        (e) => e.storeProduct.identifier.endsWith(suffix),
      );
      if (package == null) {
        getIt<Logger>().e(
          'IAP: no package matching "$suffix" among '
          '${packages.map((e) => e.storeProduct.identifier).toList()}',
        );
        throw IapException(Strings.errorViewMessage);
      }

      final result = await Purchases.purchase(PurchaseParams.package(package));
      return result.customerInfo.entitlements.all['Calora Premium']?.isActive ==
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
