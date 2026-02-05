import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:pedometer_2/pedometer_2.dart';
import 'package:permission_handler/permission_handler.dart';

@lazySingleton
class PedometerService {
  StreamSubscription<int>? _stepStreamSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;

  final _todayStepsController = StreamController<int>.broadcast();
  Stream<int> get todayStepsStream => _todayStepsController.stream;

  final _errorController = StreamController<String>.broadcast();
  Stream<String> get errorStream => _errorController.stream;

  final _statusController = StreamController<PedestrianStatus>.broadcast();
  Stream<PedestrianStatus> get statusStream => _statusController.stream;

  int _dailySteps = 0;
  int _weeklySteps = 0;
  int _monthlySteps = 0;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  int get dailySteps => _dailySteps;
  int get weeklySteps => _weeklySteps;
  int get monthlySteps => _monthlySteps;

  PedometerService();

  DateTime get _startOfDay => DateTime.now().copyWith(
    hour: 0,
    minute: 0,
    second: 0,
    millisecond: 0,
    microsecond: 0,
  );

  DateTime get _endOfDay => DateTime.now().copyWith(
    hour: 23,
    minute: 59,
    second: 59,
    millisecond: 999,
    microsecond: 999,
  );

  DateTime get _startOfWeek {
    final now = DateTime.now();
    return now
        .subtract(Duration(days: now.weekday - 1))
        .copyWith(
          hour: 0,
          minute: 0,
          second: 0,
          millisecond: 0,
          microsecond: 0,
        );
  }

  DateTime get _endOfWeek {
    final now = DateTime.now();
    return now
        .add(Duration(days: DateTime.daysPerWeek - now.weekday))
        .copyWith(
          hour: 23,
          minute: 59,
          second: 59,
          millisecond: 999,
          microsecond: 999,
        );
  }

  DateTime get _startOfMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month).copyWith(
      hour: 0,
      minute: 0,
      second: 0,
      millisecond: 0,
      microsecond: 0,
    );
  }

  DateTime get _endOfMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0).copyWith(
      hour: 23,
      minute: 59,
      second: 59,
      millisecond: 999,
      microsecond: 999,
    );
  }

  Future<bool> ensurePermissionGranted() async {
    try {
      PermissionStatus status;

      if (Platform.isAndroid) {
        status = await Permission.activityRecognition.status;
        log('Android permission status: $status', name: 'PedometerService');
        if (!status.isGranted) {
          status = await Permission.activityRecognition.request();
          log('Android permission after request: $status', name: 'PedometerService');
        }
      } else if (Platform.isIOS) {
        status = await Permission.sensors.status;
        log('iOS permission status: $status', name: 'PedometerService');

        if (status.isDenied) {
          status = await Permission.sensors.request();
          log('iOS permission after request: $status', name: 'PedometerService');
        }

        if (status.isPermanentlyDenied) {
          _emitError('permission_permanently_denied');
          log('Permission permanently denied', name: 'PedometerService');
          return false;
        }

        if (status.isDenied) {
          _emitError('permission_denied');
          log('Permission denied', name: 'PedometerService');
          return false;
        }
      } else {
        _emitError('Unsupported platform');
        return false;
      }

      if (status.isGranted) {
        log('✅ Permission GRANTED successfully', name: 'PedometerService');
        return true;
      }

      _emitError('Permission denied');
      return false;
    } catch (e, s) {
      _emitError('Permission check failed: $e');
      log('Permission error', name: 'PedometerService', error: e, stackTrace: s);
      return false;
    }
  }

  Future<void> initializePedometer() async {
    if (_isInitialized) {
      log('Pedometer already initialized', name: 'PedometerService');
      return;
    }

    log('🚀 Starting pedometer initialization...', name: 'PedometerService');

    try {
      final hasPermission = await ensurePermissionGranted();
      if (!hasPermission) {
        _isInitialized = false;
        log('❌ Initialization stopped - no permission', name: 'PedometerService');
        return;
      }

      if (Platform.isIOS) {
        log('⏳ Waiting 1 second for iOS to register permission...', name: 'PedometerService');
        await Future.delayed(const Duration(milliseconds: 1000));
      }

      log('🔍 Testing pedometer API availability...', name: 'PedometerService');
      bool apiWorks = false;

      try {
        final now = DateTime.now();
        final weekAgo = now.subtract(const Duration(days: 7));
        final testSteps = await Pedometer().getStepCount(from: weekAgo, to: now);
        log('✅ API TEST PASSED - Got $testSteps steps from last 7 days', name: 'PedometerService');
        apiWorks = true;
      } catch (e) {
        final errorStr = e.toString();
        log('⚠️ API TEST: $errorStr', name: 'PedometerService');

        if (errorStr.contains('isStepCountingAvailable') || errorStr.contains('Not isStepCountingAvailable')) {
          log('❌ FATAL: Step counting NOT available on this device', name: 'PedometerService');
          _emitError(
            'Step counting is not available. Please check Settings > Privacy & Security > Motion & Fitness > Fitness Tracking is enabled.',
          );
          _isInitialized = false;
          return;
        }

        log('✅ API works, but no historical data yet (device might be new)', name: 'PedometerService');
        apiWorks = true;
      }

      if (!apiWorks) {
        log('❌ Pedometer API not working', name: 'PedometerService');
        _isInitialized = false;
        return;
      }

      log('📊 Loading initial step counts...', name: 'PedometerService');
      await _loadInitialStepCounts();

      log('🎧 Starting step count stream...', name: 'PedometerService');
      _listenToStepCountStream();

      log('🎧 Starting pedestrian status stream...', name: 'PedometerService');
      _listenToPedestrianStatusStream();

      _isInitialized = true;
      log('✅ ✅ ✅ Pedometer service initialized SUCCESSFULLY!', name: 'PedometerService');
      log('💡 If you see 0 steps, walk around to test real-time counting', name: 'PedometerService');
    } catch (e, s) {
      _isInitialized = false;
      _emitError('Failed to initialize pedometer: $e');
      log('❌ Initialization error', name: 'PedometerService', error: e, stackTrace: s);
    }
  }

  Future<void> retryInitialization() async {
    log('🔄 Retrying pedometer initialization', name: 'PedometerService');
    _isInitialized = false;
    await initializePedometer();
  }

  void _emitTodaySteps(int steps) {
    if (!_todayStepsController.isClosed) {
      _todayStepsController.add(steps);
    }
  }

  void _emitError(String message) {
    if (!_errorController.isClosed) {
      _errorController.add(message);
    }
  }

  void _emitStatus(PedestrianStatus status) {
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  Future<void> _loadInitialStepCounts() async {
    try {
      try {
        _dailySteps = await getStepsForDateRange(_startOfDay, _endOfDay);
        _emitTodaySteps(_dailySteps);
        log('✅ Today steps: $_dailySteps', name: 'PedometerService');
      } catch (e) {
        log('⚠️ No data for today, starting from 0: $e', name: 'PedometerService');
        _dailySteps = 0;
        _emitTodaySteps(0);
      }

      try {
        _weeklySteps = await getStepsForDateRange(_startOfWeek, _endOfWeek);
        log('✅ Weekly steps: $_weeklySteps', name: 'PedometerService');
      } catch (e) {
        log('⚠️ No weekly data, starting from 0: $e', name: 'PedometerService');
        _weeklySteps = 0;
      }

      try {
        _monthlySteps = await getStepsForDateRange(_startOfMonth, _endOfMonth);
        log('✅ Monthly steps: $_monthlySteps', name: 'PedometerService');
      } catch (e) {
        log('⚠️ No monthly data, starting from 0: $e', name: 'PedometerService');
        _monthlySteps = 0;
      }

      log(
        '📊 Initial counts - Today: $_dailySteps, Weekly: $_weeklySteps, Monthly: $_monthlySteps',
        name: 'PedometerService',
      );
    } catch (e, s) {
      log('⚠️ Load initial counts error (continuing anyway)', name: 'PedometerService', error: e, stackTrace: s);
    }
  }

  void _listenToStepCountStream() {
    try {
      int lastStepCount = 0;
      bool isStreamInitialized = false;

      _stepStreamSubscription?.cancel();
      _stepStreamSubscription = Pedometer().stepCountStream().listen(
        (int steps) async {
          log('👣 Real-time step count: $steps', name: 'PedometerService');

          if (!isStreamInitialized) {
            try {
              _dailySteps = await getTodaySteps();
              lastStepCount = steps;
              isStreamInitialized = true;
              _emitTodaySteps(_dailySteps);
              log('✅ Stream initialized with $_dailySteps daily steps', name: 'PedometerService');
              return;
            } catch (e, s) {
              log('⚠️ Error getting initial daily steps, using 0: $e', name: 'PedometerService');
              _dailySteps = 0;
              lastStepCount = steps;
              isStreamInitialized = true;
              _emitTodaySteps(0);
              return;
            }
          }

          final int delta = steps - lastStepCount;

          if (delta > 0 && delta < 1000) {
            _dailySteps += delta;
            lastStepCount = steps;
            log('➕ Added $delta steps, total: $_dailySteps', name: 'PedometerService');
          } else if (delta >= 1000) {
            try {
              _dailySteps = await getTodaySteps();
              lastStepCount = steps;
              log('🔄 Large delta detected, refreshed: $_dailySteps', name: 'PedometerService');
            } catch (e, s) {
              log('⚠️ Error refreshing daily steps: $e', name: 'PedometerService');
            }
          } else if (delta < 0) {
            try {
              _dailySteps = await getTodaySteps();
              lastStepCount = steps;
              log('🔄 Counter reset detected, refreshed: $_dailySteps', name: 'PedometerService');
            } catch (e, s) {
              log('⚠️ Error handling counter reset: $e', name: 'PedometerService');
            }
          }

          _emitTodaySteps(_dailySteps);
        },
        onError: (error) {
          _emitError('Step count stream error: $error');
          log('❌ Step stream error: $error', name: 'PedometerService', error: error);
        },
        cancelOnError: false,
      );

      log('✅ Step count stream listener started', name: 'PedometerService');
    } catch (e, s) {
      _emitError('Failed to listen to step count stream: $e');
      log('❌ Stream listen error', name: 'PedometerService', error: e, stackTrace: s);
    }
  }

  void _listenToPedestrianStatusStream() {
    try {
      _pedestrianStatusSubscription?.cancel();
      _pedestrianStatusSubscription = Pedometer().pedestrianStatusStream().listen(
        (PedestrianStatus status) {
          log('🚶 Pedestrian status: $status', name: 'PedometerService');
          _emitStatus(status);
        },
        onError: (error) {
          log('⚠️ Pedestrian status error: $error', name: 'PedometerService');
        },
        cancelOnError: false,
      );

      log('✅ Pedestrian status stream listener started', name: 'PedometerService');
    } catch (e, s) {
      log('⚠️ Pedestrian stream error (non-critical)', name: 'PedometerService', error: e, stackTrace: s);
    }
  }

  Future<int> getStepsForDateRange(DateTime from, DateTime to) async {
    try {
      final steps = await Pedometer().getStepCount(from: from, to: to);
      return steps;
    } catch (e, s) {
      log('❌ Get steps error for range ${from.toString()} to ${to.toString()}: $e', name: 'PedometerService');
      rethrow;
    }
  }

  Future<int> getTodaySteps() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    return await getStepsForDateRange(todayStart, todayEnd);
  }

  Future<int> getWeeklySteps() async => await getStepsForDateRange(_startOfWeek, _endOfWeek);
  Future<int> getMonthlySteps() async => await getStepsForDateRange(_startOfMonth, _endOfMonth);

  Future<Map<DateTime, int>> getDailyStepsForRange(DateTime fromDate, DateTime toDate) async {
    final Map<DateTime, int> result = {};

    DateTime current = DateTime(fromDate.year, fromDate.month, fromDate.day);
    final end = DateTime(toDate.year, toDate.month, toDate.day);

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      try {
        final dayStart = current;
        final dayEnd = DateTime(current.year, current.month, current.day, 23, 59, 59, 999);

        final steps = await getStepsForDateRange(dayStart, dayEnd);
        result[current] = steps;

        log('Steps for ${current.toIso8601String().split('T')[0]}: $steps', name: 'PedometerService');
      } catch (e) {
        log('Error getting steps for ${current.toIso8601String().split('T')[0]}: $e', name: 'PedometerService');
        result[current] = 0;
      }

      current = current.add(const Duration(days: 1));
    }

    return result;
  }

  Future<bool> isPedometerAvailable() async {
    try {
      final now = DateTime.now();
      await Pedometer().getStepCount(
        from: now.subtract(const Duration(minutes: 1)),
        to: now,
      );
      return true;
    } catch (e) {
      log('Pedometer availability check failed: $e', name: 'PedometerService', error: e);
      return false;
    }
  }

  Future<void> dispose() async {
    await _stepStreamSubscription?.cancel();
    await _pedestrianStatusSubscription?.cancel();

    _stepStreamSubscription = null;
    _pedestrianStatusSubscription = null;

    _isInitialized = false;

    await _todayStepsController.close();
    await _errorController.close();
    await _statusController.close();

    log('Pedometer service disposed', name: 'PedometerService');
  }
}
