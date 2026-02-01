import 'dart:developer';
import 'dart:io';
import 'package:flutter/services.dart';

class StepsForegroundService {
  StepsForegroundService._();
  static final instance = StepsForegroundService._();

  static const MethodChannel _ch = MethodChannel('ai.calora.app/steps_native_fgs');

  int _goalSteps = 10000;
  bool _started = false;

  void setGoalSteps(int goal) {
    _goalSteps = goal <= 0 ? 10000 : goal;
  }

  Future<bool> start({int initialSteps = 0}) async {
    if (!Platform.isAndroid) return false;

    try {
      await _ch.invokeMethod('start', {
        'steps': initialSteps,
        'goal': _goalSteps,
      });
      _started = true;
      log('Native FGS started', name: 'StepsForegroundService');
      return true;
    } catch (e, s) {
      log('Native FGS start error: $e', name: 'StepsForegroundService');
      log('$s', name: 'StepsForegroundService');
      return false;
    }
  }

  Future<void> updateSteps(int steps) async {
    if (!Platform.isAndroid) return;
    if (!_started) return;

    try {
      await _ch.invokeMethod('update', {
        'steps': steps,
        'goal': _goalSteps,
      });
    } catch (e) {
      log('Native FGS update error: $e', name: 'StepsForegroundService');
    }
  }

  Future<void> stop() async {
    if (!Platform.isAndroid) return;

    try {
      await _ch.invokeMethod('stop');
    } catch (e) {
      log('Native FGS stop error: $e', name: 'StepsForegroundService');
    } finally {
      _started = false;
    }
  }

  bool get isRunning => _started;
}
