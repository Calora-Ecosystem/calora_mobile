import 'dart:developer';
import 'dart:io';
import 'package:flutter/services.dart';

class StepsForegroundService {
  StepsForegroundService._();

  static final instance = StepsForegroundService._();

  static const MethodChannel _ch = MethodChannel('ai.calora.app/steps_native_fgs');

  /// Notification authority modes — must match StepsFgService.MODE_*.
  static const String modeSensor = 'sensor';
  static const String modeMirror = 'mirror';

  int _goalSteps = 10000;
  double _weightKg = 70;
  bool _started = false;
  String _mode = modeSensor;

  void setGoalSteps(int goal) {
    _goalSteps = goal <= 0 ? 10000 : goal;
  }

  void setUserWeight(double w) {
    if (w <= 0) return;
    _weightKg = w;
  }

  /// [mode] decides whether the native service drives the notification
  /// from its own sensor ([modeSensor], pedometer fallback) or just
  /// mirrors the value Flutter pushes ([modeMirror], Health Connect).
  Future<bool> start({String mode = modeSensor}) async {
    if (!Platform.isAndroid) return false;

    _mode = mode;
    try {
      final res = await _ch.invokeMethod<bool>('start', {
        'goal': _goalSteps,
        'weight_kg': _weightKg,
        'mode': mode,
      });
      _started = res ?? true;
      return _started;
    } catch (e) {
      _started = false;
      return false;
    }
  }

  /// Today's step total the native foreground service has persisted.
  /// Keeps advancing while the app is closed (pedometer fallback), so
  /// this is how Flutter recovers background-counted steps on resume.
  Future<int> currentNativeSteps() async {
    if (!Platform.isAndroid) return 0;
    try {
      final res = await _ch.invokeMethod<int>('getNativeSteps');
      return res ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Last 30 days of daily step totals the native FG service persisted
  /// on each midnight rollover, keyed by ISO date (`yyyy-MM-dd`).
  /// Empty on iOS. Empty on Android if the service has never run
  /// through a midnight — that's fine, the caller merges with the
  /// existing ledger.
  Future<Map<String, int>> getNativeHistory() async {
    if (!Platform.isAndroid) return const {};
    try {
      final res = await _ch.invokeMethod<Map<dynamic, dynamic>>('getStepsHistory');
      if (res == null) return const {};
      return res.map((k, v) => MapEntry(k as String, (v as num).toInt()));
    } catch (e) {
      log('getStepsHistory failed: $e', name: 'StepsForegroundService');
      return const {};
    }
  }

  /// Idempotent nudge: starts the FG service if not already running.
  /// Used by the periodic WorkManager sync as a watchdog so an OEM
  /// service-kill is recovered from within 15 min at worst.
  Future<void> ensureRunning() async {
    if (!Platform.isAndroid) return;
    try {
      final res = await _ch.invokeMethod<bool>('ensureRunning');
      if (res == true) _started = true;
    } catch (e) {
      log('ensureRunning failed: $e', name: 'StepsForegroundService');
    }
  }

  Future<void> updateGoal(int goal) async {
    if (!Platform.isAndroid) return;

    _goalSteps = goal <= 0 ? 10000 : goal;
    if (!_started) return;

    try {
      await _ch.invokeMethod('update_goal', {'goal': _goalSteps});
    } catch (e, s) {
      log('Native FGS update_goal error: $e', name: 'StepsForegroundService', stackTrace: s);
    }
  }

  Future<void> syncSteps(int steps, {String? mode}) async {
    if (!Platform.isAndroid) return;
    if (!_started) return;

    final syncMode = mode ?? _mode;
    try {
      await _ch.invokeMethod('sync', {
        'steps': steps,
        'weight_kg': _weightKg,
        'mode': syncMode,
      });
    } catch (e, s) {
      log('Native FGS sync error: $e', name: 'StepsForegroundService', stackTrace: s);
    }
  }

  Future<void> stop() async {
    if (!Platform.isAndroid) return;

    try {
      await _ch.invokeMethod('stop');
    } catch (e, s) {
      log('Native FGS stop error: $e', name: 'StepsForegroundService', stackTrace: s);
    } finally {
      _started = false;
    }
  }

  bool get isRunning => _started;
}
