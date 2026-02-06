import 'dart:developer';
import 'dart:io';
import 'package:flutter/services.dart';

class StepsForegroundService {
  StepsForegroundService._();
  static final instance = StepsForegroundService._();

  static const MethodChannel _ch = MethodChannel('ai.calora.app/steps_native_fgs');

  int _goalSteps = 10000;
  double _weightKg = 70;
  bool _started = false;

  void setGoalSteps(int goal) {
    _goalSteps = goal <= 0 ? 10000 : goal;
  }

  void setUserWeight(double w) {
    if (w <= 0) return;
    _weightKg = w;
  }

  Future<bool> start() async {
    if (!Platform.isAndroid) return false;

    try {
      final res = await _ch.invokeMethod<bool>('start', {
        'goal': _goalSteps,
        'weight_kg': _weightKg,
      });
      _started = res ?? true;
      return _started;
    } catch (e, s) {
      _started = false;
      return false;
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

  Future<void> syncSteps(int steps) async {
    if (!Platform.isAndroid) return;
    if (!_started) return;

    try {
      await _ch.invokeMethod('sync', {
        'steps': steps,
        'weight_kg': _weightKg,
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
