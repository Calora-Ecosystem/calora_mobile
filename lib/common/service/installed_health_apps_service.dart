// lib/common/service/installed_health_apps_service.dart

import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';

class InstalledHealthAppsService {
  static const String samsungHealthPackage = 'com.sec.android.app.shealth';
  static const String miFitnessPackage = 'com.mi.health';
  static const String xiaomiHealthPackage = 'com.xiaomi.hm.health';
  static const String healthConnectPackage = 'com.google.android.apps.healthdata';

  /// Telefon brendiga qarab ehtimoliy fitness app'ni taxmin qiladi.
  /// 100% aniq bilib olishning o'rniga — platforma belgilariga tayanamiz
  static Future<String?> detectPrimaryHealthApp() async {
    if (!Platform.isAndroid) return null;

    try {
      // android_intent_plus orqali package mavjudligini tekshirish
      // Har birini ochishga urinamiz (silent mode, faqat tekshiruv)
      if (await _canResolvePackage(samsungHealthPackage)) {
        return 'samsung_health';
      }
      if (await _canResolvePackage(miFitnessPackage)) {
        return 'mi_fitness';
      }
      if (await _canResolvePackage(xiaomiHealthPackage)) {
        return 'mi_fitness'; // eski Mi Fit
      }
    } catch (_) {}

    return 'unknown';
  }

  /// Package mavjudligini tekshirish — Intent yaratib, canResolve orqali
  static Future<bool> _canResolvePackage(String packageName) async {
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.MAIN',
        package: packageName,
      );
      // canResolveActivity metodi android_intent_plus 5.0+'da bor
      return await intent.canResolveActivity() ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openSamsungHealthSettings() async {
    await _launchPackage(samsungHealthPackage);
  }

  static Future<void> openMiFitnessSettings() async {
    // Ikkalasini ham urinib ko'ramiz
    if (!await _launchPackage(miFitnessPackage)) {
      await _launchPackage(xiaomiHealthPackage);
    }
  }

  static Future<void> openHealthConnectSettings() async {
    if (!Platform.isAndroid) return;

    try {
      const intent = AndroidIntent(
        action: 'androidx.health.ACTION_HEALTH_CONNECT_SETTINGS',
      );
      await intent.launch();
    } catch (_) {
      await _launchPackage(healthConnectPackage);
    }
  }

  static Future<bool> _launchPackage(String packageName) async {
    if (!Platform.isAndroid) return false;
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.MAIN',
        package: packageName,
      );
      await intent.launch();
      return true;
    } catch (_) {
      // App not installed — do NOT redirect to the Play Store. Report
      // failure so the caller can fall back silently to the native
      // sensor instead of prompting an install.
      return false;
    }
  }
}
