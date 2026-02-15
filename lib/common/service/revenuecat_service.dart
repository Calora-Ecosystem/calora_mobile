import 'dart:io';

import 'package:calora/common/base/profile_store.dart';
import 'package:calora/domain/model/profile/profile_request.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
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

    PurchasesConfiguration configuration;
    if (Platform.isAndroid) {
      configuration = PurchasesConfiguration(
        'test_RqQDCjIEQygqykNoXndFdysWVWJ',
      );
    } else {
      configuration = PurchasesConfiguration(
        'appl_VZdWGZmrtjFMtQWQfdlEbRYulSJ',
      );
    }

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
}
