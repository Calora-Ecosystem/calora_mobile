import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Thin wrapper over the native (`MainActivity`) deep links that help the
/// user keep the step foreground service alive (battery whitelist / OEM
/// autostart) and manage another app's Health Connect data sharing.
///
/// All methods are Android-only no-ops elsewhere.
class DeviceCareService {
  const DeviceCareService._();

  static const MethodChannel _ch = MethodChannel('ai.calora.app/steps_native_fgs');

  /// Health Connect package ids of the common trackers, keyed by the
  /// `detectedApp` value the step service emits.
  static const Map<String, String> _trackerPackages = {
    'samsung_health': 'com.sec.android.app.shealth',
    'mi_fitness': 'com.mi.health',
  };

  /// Whether the app is already exempt from battery optimization. Returns
  /// `true` off Android so callers treat non-Android as "nothing to do".
  static Future<bool> isIgnoringBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;
    try {
      final res = await _ch.invokeMethod<bool>('isIgnoringBatteryOptimizations');
      return res ?? false;
    } catch (e) {
      _log('isIgnoringBatteryOptimizations', e);
      return false;
    }
  }

  /// Opens the system "ignore battery optimizations" prompt for this app.
  static Future<void> requestIgnoreBatteryOptimizations() async {
    if (!Platform.isAndroid) return;
    try {
      await _ch.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (e) {
      _log('requestIgnoreBatteryOptimizations', e);
    }
  }

  /// Opens the OEM autostart / background-activity screen (best effort;
  /// falls back to this app's details page natively).
  static Future<void> openAutoStartSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _ch.invokeMethod('openAutoStartSettings');
    } catch (e) {
      _log('openAutoStartSettings', e);
    }
  }

  /// Opens this app's system details page.
  static Future<void> openAppDetailsSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _ch.invokeMethod('openAppDetailsSettings');
    } catch (e) {
      _log('openAppDetailsSettings', e);
    }
  }

  /// Opens the Health Connect screen where the user manages what the
  /// given tracker may read/write — i.e. where they flip "Allow all" so
  /// Samsung Health / Google Fit writes Steps into Health Connect.
  ///
  /// [detectedApp] is the step service's tracker id (`samsung_health`,
  /// `mi_fitness`, …); unknown values fall back to Health Connect's main
  /// settings natively.
  static Future<void> openHealthConnectAppPermissions({String? detectedApp}) async {
    if (!Platform.isAndroid) return;
    try {
      await _ch.invokeMethod('openHealthConnectAppPermissions', {
        'package': _trackerPackages[detectedApp],
      });
    } catch (e) {
      _log('openHealthConnectAppPermissions', e);
    }
  }

  static void _log(String method, Object e) {
    if (kDebugMode) debugPrint('DeviceCareService.$method failed: $e');
  }
}
