import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class HealthSettingsService {
  static const MethodChannel _channel = MethodChannel('ai.calora.app/steps_native_fgs');

  static Future<void> openHealthConnectSettings() async {
    try {
      await _channel.invokeMethod('openHealthConnectSettings');
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Failed to open Health Connect settings: '${e.message}'.");
      }
    }
  }
}
