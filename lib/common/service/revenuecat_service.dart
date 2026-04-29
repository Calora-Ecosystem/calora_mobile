import 'dart:io';

import 'package:calora/common/base/profile_store.dart';
import 'package:calora/common/di/injection.dart';
import 'package:calora/common/widgets/display/display.dart';
import 'package:calora/domain/model/profile/profile_request.dart';
import 'package:calora/presentation/premium/management/premium_management.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

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

  Future<void> login(ProfileRequest? user) async {
    if (user == null) return;
    await Purchases.logIn(user.userId!.toString());
    await Purchases.setEmail(user.email ?? '');
    await Purchases.setDisplayName(user.name ?? '');
  }

  Future<bool> purchase(
    PlanModel plan, [
    bool restore = false,
  ]) async {
    try {
      final offerings = await Purchases.getOfferings();
      final offering = offerings.all['default']!;

      CustomerInfo customerInfo;
      if (restore) {
        customerInfo = await Purchases.restorePurchases();
      } else {
        final packages = offering.availablePackages;
        packages.forEach((package) {
          print(package.storeProduct.identifier);
        });
        final package = packages.firstWhere(
          (e) =>
              e.storeProduct.identifier.endsWith('${Platform.isAndroid ? '-' : '_'}${plan.id}'),
        );
        final params = PurchaseParams.package(package);


        await Purchases.setAttributes({'order_id': ''});
        await Purchases.syncAttributesAndOfferingsIfNeeded();

        final result = await Purchases.purchase(params);
        customerInfo = result.customerInfo;
      }

      final entitlement = customerInfo.entitlements.all['Calora Premium'];
      if (entitlement?.isActive != true) {
        if (restore) {
          getIt<Display>().info(description: 'No previous purchase');
        }
        return false;
      }
      return true;
    } on PlatformException catch (e, st) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      getIt<Logger>().e(e.toString(), stackTrace: st);
      return false;
    }
  }
}
