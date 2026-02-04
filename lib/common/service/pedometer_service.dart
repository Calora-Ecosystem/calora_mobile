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
        status = await Permission.activityRecognition.request();
      } else if (Platform.isIOS) {
        status = await Permission.sensors.request();
      } else {
        _emitError('Unsupported platform');
        return false;
      }

      if (status.isGranted) return true;

      if (status.isPermanentlyDenied) {
        _emitError('Permission permanently denied. Enable it in settings.');
      } else {
        _emitError('Permission denied: $status');
      }
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

    try {
      final isAvailable = await isPedometerAvailable();
      if (!isAvailable) {
        throw Exception('Pedometer not available on this device');
      }

      await _loadInitialStepCounts();
      _listenToStepCountStream();
      _listenToPedestrianStatusStream();

      _isInitialized = true;
      log('Pedometer service initialized successfully', name: 'PedometerService');
    } catch (e, s) {
      _isInitialized = false;
      _emitError('Failed to initialize pedometer: $e');
      log('Initialization error', name: 'PedometerService', error: e, stackTrace: s);
      rethrow;
    }
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
      _dailySteps = await getStepsForDateRange(_startOfDay, _endOfDay);
      _emitTodaySteps(_dailySteps);

      _weeklySteps = await getStepsForDateRange(_startOfWeek, _endOfWeek);
      _monthlySteps = await getStepsForDateRange(_startOfMonth, _endOfMonth);

      log(
        'Initial step counts loaded - Today: $_dailySteps, Weekly: $_weeklySteps, Monthly: $_monthlySteps',
        name: 'PedometerService',
      );
    } catch (e, s) {
      _emitError('Failed to load initial step counts: $e');
      log('Load initial counts error', name: 'PedometerService', error: e, stackTrace: s);
    }
  }

  void _listenToStepCountStream() {
    try {
      int lastStepCount = 0;
      bool isStreamInitialized = false;

      _stepStreamSubscription?.cancel();
      _stepStreamSubscription = Pedometer().stepCountStream().listen(
        (int steps) async {
          log('Real-time step count: $steps', name: 'PedometerService');

          if (!isStreamInitialized) {
            try {
              _dailySteps = await getTodaySteps();
              lastStepCount = steps;
              isStreamInitialized = true;
              _emitTodaySteps(_dailySteps);
              return;
            } catch (e, s) {
              _emitError('Error getting initial daily steps: $e');
              log('Init daily steps error', name: 'PedometerService', error: e, stackTrace: s);
              return;
            }
          }

          final int delta = steps - lastStepCount;

          if (delta > 0 && delta < 1000) {
            _dailySteps += delta;
            lastStepCount = steps;
          } else if (delta >= 1000) {
            try {
              _dailySteps = await getTodaySteps();
              lastStepCount = steps;
            } catch (e, s) {
              _emitError('Error refreshing daily steps: $e');
              log('Refresh daily steps error', name: 'PedometerService', error: e, stackTrace: s);
            }
          } else if (delta < 0) {
            try {
              _dailySteps = await getTodaySteps();
              lastStepCount = steps;
            } catch (e, s) {
              _emitError('Error handling counter reset: $e');
              log('Counter reset error', name: 'PedometerService', error: e, stackTrace: s);
            }
          }

          _emitTodaySteps(_dailySteps);
        },
        onError: (error) {
          _emitError('Step count stream error: $error');
          log('Step stream error', name: 'PedometerService', error: error);
        },
        cancelOnError: false,
      );
    } catch (e, s) {
      _emitError('Failed to listen to step count stream: $e');
      log('Stream listen error', name: 'PedometerService', error: e, stackTrace: s);
    }
  }

  void _listenToPedestrianStatusStream() {
    try {
      _pedestrianStatusSubscription?.cancel();
      _pedestrianStatusSubscription = Pedometer().pedestrianStatusStream().listen(
        (PedestrianStatus status) {
          log('Pedestrian status: $status', name: 'PedometerService');
          _emitStatus(status);
        },
        onError: (error) {
          _emitError('Pedestrian status stream error: $error');
          log('Pedestrian status error', name: 'PedometerService', error: error);
        },
        cancelOnError: false,
      );
    } catch (e, s) {
      _emitError('Failed to listen to pedestrian status stream: $e');
      log('Pedestrian stream error', name: 'PedometerService', error: e, stackTrace: s);
    }
  }

  Future<int> getStepsForDateRange(DateTime from, DateTime to) async {
    try {
      final steps = await Pedometer().getStepCount(from: from, to: to);
      return steps;
    } catch (e, s) {
      _emitError('Failed to get steps for date range: $e');
      log('Get steps error', name: 'PedometerService', error: e, stackTrace: s);
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
      await Pedometer().getStepCount(
        from: DateTime.now().subtract(const Duration(hours: 1)),
        to: DateTime.now(),
      );
      return true;
    } catch (e) {
      log('Pedometer not available', name: 'PedometerService', error: e);
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
