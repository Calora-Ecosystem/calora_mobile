import 'dart:async';
import 'dart:io';

import 'package:calora_steps/src/models.dart';
import 'package:flutter/services.dart';

export 'src/models.dart';

class CaloraSteps {
  const CaloraSteps._();

  static const MethodChannel _methods = MethodChannel('calora_steps');
  static const EventChannel _events = EventChannel('calora_steps/updates');

  static bool get isSupported => Platform.isAndroid;

  static Stream<StepSnapshot>? _updates;

  static Stream<StepSnapshot> get updates {
    if (!isSupported) return const Stream.empty();
    return _updates ??= _events
        .receiveBroadcastStream()
        .where((event) => event is Map)
        .map((event) => StepSnapshot.fromMap(event as Map<Object?, Object?>))
        .asBroadcastStream();
  }

  static Future<StepSnapshot> start() => _snapshotCall('start');

  static Future<void> stop() => _call<void>('stop');

  static Future<bool> ensureRunning() async =>
      await _call<bool>('ensureRunning') ?? false;

  static Future<void> configure({
    int? goal,
    double? weightKg,
    double? kcalPerStep,
    StepNotificationLabels? labels,
  }) => _call<void>('configure', {
    'goal': ?goal,
    'weightKg': ?weightKg,
    'kcalPerStep': ?kcalPerStep,
    'labels': ?labels?.toMap(),
  });

  static Future<StepSnapshot> snapshot() => _snapshotCall('snapshot');

  static Future<StepSnapshot> refresh({bool force = false}) =>
      _snapshotCall('refresh', {'force': force});

  static Future<Map<String, int>> history({
    int days = 30,
    bool refresh = false,
    bool force = false,
  }) async {
    final raw = await _call<Map<Object?, Object?>>('history', {
      'days': days,
      'refresh': refresh,
      'force': force,
    });
    if (raw == null) return const {};
    return {
      for (final entry in raw.entries)
        if (entry.key is String && entry.value is num)
          entry.key! as String: (entry.value! as num).toInt(),
    };
  }

  static Future<StepTrackingStatus> status() async {
    final raw = await _call<Map<Object?, Object?>>('status');
    return raw == null
        ? StepTrackingStatus.unknown
        : StepTrackingStatus.fromMap(raw);
  }

  static Future<HealthConnectConnectResult> connectHealthConnect() async {
    final raw = await _call<Map<Object?, Object?>>('connectHealthConnect');
    return HealthConnectConnectResult.fromWire(raw?['result']);
  }

  static Future<bool> openHealthConnect() async =>
      await _call<bool>('openHealthConnect') ?? false;

  static Future<bool> installHealthConnect() async =>
      await _call<bool>('installHealthConnect') ?? false;

  static Future<bool> openTracker(String packageName) async =>
      await _call<bool>('openTracker', {'package': packageName}) ?? false;

  static Future<bool> requestIgnoreBatteryOptimizations() async =>
      await _call<bool>('requestIgnoreBatteryOptimizations') ?? false;

  static Future<bool> openAutoStart() async =>
      await _call<bool>('openAutoStart') ?? false;

  static Future<bool> openAppSettings() async =>
      await _call<bool>('openAppSettings') ?? false;

  static Future<bool> openNotificationSettings() async =>
      await _call<bool>('openNotificationSettings') ?? false;

  static Future<StepSnapshot> _snapshotCall(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    final raw = await _call<Map<Object?, Object?>>(method, arguments);
    return raw == null ? StepSnapshot.empty : StepSnapshot.fromMap(raw);
  }

  static Future<T?> _call<T>(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    if (!isSupported) return null;
    try {
      return await _methods.invokeMethod<T>(method, arguments);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
