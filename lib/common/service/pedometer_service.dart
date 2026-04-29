import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:pedometer_2/pedometer_2.dart';
import 'package:permission_handler/permission_handler.dart';

@lazySingleton
class PedometerService {
  StreamSubscription<int>? _stepStreamSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;

  final _stepsController = StreamController<int>.broadcast();

  Stream<int> get stepCountStream => _stepsController.stream;

  final _errorController = StreamController<String>.broadcast();

  Stream<String> get errorStream => _errorController.stream;

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  static Future<bool>? _globalPermissionFuture;

  PedometerService();

  Future<bool> hasPermission() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.activityRecognition.status;
        return status.isGranted;
      }
      if (Platform.isIOS) {
        final status = await Permission.sensors.status;
        return status.isGranted;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> ensurePermissionGranted() {
    if (_globalPermissionFuture != null) {
      return _globalPermissionFuture!;
    }

    _globalPermissionFuture = _ensurePermissionGrantedInternal().whenComplete(() {
      Future.delayed(const Duration(milliseconds: 500), () {
        _globalPermissionFuture = null;
      });
    });

    return _globalPermissionFuture!;
  }

  Future<bool> _ensurePermissionGrantedInternal() async {
    try {
      PermissionStatus status;
      if (Platform.isAndroid) {
        status = await Permission.activityRecognition.request();
        if (status.isPermanentlyDenied) {
          _emitError('permission_permanently_denied');
        }
        return status.isGranted;
      }

      if (Platform.isIOS) {
        status = await Permission.sensors.request();
        if (status.isPermanentlyDenied) {
          _emitError('permission_permanently_denied');
        }
        return status.isGranted;
      }

      _emitError('unsupported_platform');
      return false;
    } catch (e) {
      _emitError('permission_check_failed: $e');
      return false;
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    final hasPerm = await ensurePermissionGranted();
    if (!hasPerm) {
      _emitError('permission_not_granted');
      return;
    }

    try {
      _listenToStepCountStream();
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      _emitError('initialization_failed: $e');
    }
  }

  void _emitError(String message) {
    if (!_errorController.isClosed) _errorController.add(message);
  }

  void _listenToStepCountStream() {
    try {
      _stepStreamSubscription?.cancel();
      _stepStreamSubscription = Pedometer().stepCountStream().listen(
        (steps) {
          if (!_stepsController.isClosed) {
            _stepsController.add(steps);
          }
        },
        onError: (error) {
          _emitError('step_stream_error: $error');
        },
        cancelOnError: false,
      );
    } catch (e) {
      _emitError('stream_start_failed: $e');
    }
  }

  Future<int> getCurrentSteps() async {
    final completer = Completer<int>();
    StreamSubscription<int>? sub;

    sub = Pedometer().stepCountStream().listen(
      (steps) {
        if (!completer.isCompleted) {
          completer.complete(steps);
          sub?.cancel();
        }
      },
      onError: (e) {
        if (!completer.isCompleted) {
          completer.completeError(e);
          sub?.cancel();
        }
      },
    );

    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        sub?.cancel();
        throw TimeoutException('Pedometer sensor did not respond in time');
      },
    );
  }

  Future<int> getStepsForDateRange(DateTime from, DateTime to) async {
    try {
      return await Pedometer().getStepCount(from: from, to: to);
    } catch (e) {
      return 0;
    }
  }

  Future<int> getTodaySteps() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return await getStepsForDateRange(todayStart, now);
  }

  Future<void> dispose() async {
    await _stepStreamSubscription?.cancel();
    await _pedestrianStatusSubscription?.cancel();
    await _stepsController.close();
    await _errorController.close();

    _isInitialized = false;
    log('Pedometer service disposed', name: 'PedometerService');
  }
}
