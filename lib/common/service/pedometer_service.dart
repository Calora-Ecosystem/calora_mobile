import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:injectable/injectable.dart';
import 'package:pedometer_2/pedometer_2.dart';
import 'package:permission_handler/permission_handler.dart';

@injectable
class PedometerService {
  // Stream subscriptions
  StreamSubscription<int>? _stepStreamSubscription;
  StreamSubscription<int>? _stepStreamFromSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;

  // Current step counts
  int _dailySteps = 0;
  int _weeklySteps = 0;
  int _monthlySteps = 0;

  // Initialization flag
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Getters for current step counts
  int get dailySteps => _dailySteps;
  int get weeklySteps => _weeklySteps;
  int get monthlySteps => _monthlySteps;

  // Callbacks for UI updates - SEPARATE callbacks for each time period
  final ValueChanged<int>? onTodayStepCountUpdated;
  final ValueChanged<int>? onWeeklyStepCountUpdated;
  final ValueChanged<int>? onMonthlyStepCountUpdated;
  final ValueChanged<PedestrianStatus>? onPedestrianStatusUpdated;
  final ValueChanged<String>? onError;

  PedometerService({
    this.onTodayStepCountUpdated,
    this.onWeeklyStepCountUpdated,
    this.onMonthlyStepCountUpdated,
    this.onPedestrianStatusUpdated,
    this.onError,
  });

  // Date calculations
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

  /// Check and request necessary permissions
  Future<bool> checkPermissions() async {
    try {
      PermissionStatus permissionStatus;

      if (Platform.isAndroid) {
        permissionStatus = await Permission.activityRecognition.request();
      } else if (Platform.isIOS) {
        permissionStatus = await Permission.sensors.request();
      } else {
        throw Exception('Unsupported platform');
      }

      if (permissionStatus.isGranted) {
        await initializePedometer();
        return true;
      } else if (permissionStatus.isPermanentlyDenied) {
        onError?.call(
          'Permission permanently denied. Please enable in device settings.',
        );
        return false;
      } else if (permissionStatus.isDenied) {
        onError?.call('Permission denied: $permissionStatus');
        return false;
      } else {
        onError?.call('Permission status: $permissionStatus');
        return false;
      }
    } catch (e, stackTrace) {
      onError?.call('Permission check failed: $e');
      log(
        'Permission error',
        name: 'PedometerService',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Initialize pedometer and start listening to streams
  Future<void> initializePedometer() async {
    if (_isInitialized) {
      log('Pedometer already initialized', name: 'PedometerService');
      return;
    }

    try {
      // Check if pedometer is available first
      final isAvailable = await isPedometerAvailable();
      if (!isAvailable) {
        throw Exception('Pedometer not available on this device');
      }

      // Load initial step counts
      await _loadInitialStepCounts();

      // Start listening to real-time streams
      _listenToStepCountStream();
      _listenToPedestrianStatusStream();

      _isInitialized = true;
      log('Pedometer service initialized successfully', name: 'PedometerService');
    } catch (e, stackTrace) {
      _isInitialized = false;
      onError?.call('Failed to initialize pedometer: $e');
      log(
        'Initialization error',
        name: 'PedometerService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Load initial step counts for all time periods
  Future<void> _loadInitialStepCounts() async {
    try {
      // Get daily steps
      _dailySteps = await getStepsForDateRange(_startOfDay, _endOfDay);
      onTodayStepCountUpdated?.call(_dailySteps);

      // Get weekly steps
      _weeklySteps = await getStepsForDateRange(_startOfWeek, _endOfWeek);
      onWeeklyStepCountUpdated?.call(_weeklySteps);

      // Get monthly steps
      _monthlySteps = await getStepsForDateRange(_startOfMonth, _endOfMonth);
      onMonthlyStepCountUpdated?.call(_monthlySteps);

      log(
        'Initial step counts loaded - Today: $_dailySteps, Weekly: $_weeklySteps, Monthly: $_monthlySteps',
        name: 'PedometerService',
      );
    } catch (e, stackTrace) {
      onError?.call('Failed to load initial step counts: $e');
      log(
        'Load initial counts error',
        name: 'PedometerService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Listen to real-time step count stream (for daily updates)
  void _listenToStepCountStream() {
    try {
      int lastStepCount = 0;
      bool isStreamInitialized = false;

      _stepStreamSubscription = Pedometer().stepCountStream().listen(
        (int steps) async {
          log('Real-time step count: $steps', name: 'PedometerService');

          if (!isStreamInitialized) {
            // First reading - get today's actual steps
            try {
              _dailySteps = await getTodaySteps();
              lastStepCount = steps;
              isStreamInitialized = true;
              log('Initial daily steps: $_dailySteps', name: 'PedometerService');
            } catch (e) {
              log(
                'Error getting initial daily steps',
                name: 'PedometerService',
                error: e,
              );
              return;
            }
          } else {
            // Calculate steps since last update
            final int stepsSinceLastUpdate = steps - lastStepCount;

            // Validate step increment
            if (stepsSinceLastUpdate > 0 && stepsSinceLastUpdate < 1000) {
              // Normal step increment
              _dailySteps += stepsSinceLastUpdate;
              lastStepCount = steps;
              log(
                'Added $stepsSinceLastUpdate steps, Total today: $_dailySteps',
                name: 'PedometerService',
              );
            } else if (stepsSinceLastUpdate >= 1000) {
              // Large jump detected, refresh from source
              log(
                'Large step jump detected ($stepsSinceLastUpdate), refreshing from source',
                name: 'PedometerService',
              );
              try {
                _dailySteps = await getTodaySteps();
                lastStepCount = steps;
              } catch (e) {
                log(
                  'Error refreshing daily steps',
                  name: 'PedometerService',
                  error: e,
                );
              }
            } else if (stepsSinceLastUpdate < 0) {
              // Counter reset (new day or app restart)
              log(
                'Step counter reset detected, refreshing',
                name: 'PedometerService',
              );
              try {
                _dailySteps = await getTodaySteps();
                lastStepCount = steps;
              } catch (e) {
                log(
                  'Error handling counter reset',
                  name: 'PedometerService',
                  error: e,
                );
              }
            }
          }

          onTodayStepCountUpdated?.call(_dailySteps);
        },
        onError: (error) {
          onError?.call('Step count stream error: $error');
          log('Step stream error', name: 'PedometerService', error: error);
        },
        cancelOnError: false,
      );
    } catch (e, stackTrace) {
      onError?.call('Failed to listen to step count stream: $e');
      log(
        'Stream listen error',
        name: 'PedometerService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Listen to pedestrian status stream
  void _listenToPedestrianStatusStream() {
    try {
      _pedestrianStatusSubscription = Pedometer().pedestrianStatusStream().listen(
        (PedestrianStatus status) {
          log('Pedestrian status: $status', name: 'PedometerService');
          onPedestrianStatusUpdated?.call(status);
        },
        onError: (error) {
          onError?.call('Pedestrian status stream error: $error');
          log(
            'Pedestrian status error',
            name: 'PedometerService',
            error: error,
          );
        },
        cancelOnError: false,
      );
    } catch (e, stackTrace) {
      onError?.call('Failed to listen to pedestrian status stream: $e');
      log(
        'Pedestrian stream error',
        name: 'PedometerService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get steps for a custom date range
  Future<int> getStepsForDateRange(DateTime from, DateTime to) async {
    try {
      final steps = await Pedometer().getStepCount(from: from, to: to);
      log(
        'Steps from ${from.toIso8601String()} to ${to.toIso8601String()}: $steps',
        name: 'PedometerService',
      );
      return steps;
    } catch (e, stackTrace) {
      onError?.call('Failed to get steps for date range: $e');
      log(
        'Get steps error',
        name: 'PedometerService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get today's steps
  Future<int> getTodaySteps() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    return await getStepsForDateRange(todayStart, todayEnd);
  }

  /// Get weekly steps
  Future<int> getWeeklySteps() async {
    return await getStepsForDateRange(_startOfWeek, _endOfWeek);
  }

  /// Get monthly steps
  Future<int> getMonthlySteps() async {
    return await getStepsForDateRange(_startOfMonth, _endOfMonth);
  }

  /// Get daily steps for a date range (for charts/history)
  Future<Map<DateTime, int>> getDailyStepsForRange(
    DateTime fromDate,
    DateTime toDate,
  ) async {
    try {
      final Map<DateTime, int> dailySteps = {};

      // Normalize dates to start of day
      final startDate = DateTime(fromDate.year, fromDate.month, fromDate.day);
      final endDate = DateTime(toDate.year, toDate.month, toDate.day);

      // Iterate through each day in the range
      DateTime currentDate = startDate;

      while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
        // Define start and end of current day
        final dayStart = currentDate;
        final dayEnd = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
          23,
          59,
          59,
          999,
        );

        // Get steps for this day
        final steps = await getStepsForDateRange(dayStart, dayEnd);

        // Store in map with normalized date as key
        dailySteps[currentDate] = steps;

        log(
          'Steps for ${currentDate.toIso8601String().split('T')[0]}: $steps',
          name: 'PedometerService',
        );

        // Move to next day
        currentDate = currentDate.add(const Duration(days: 1));
      }

      return dailySteps;
    } catch (e, stackTrace) {
      onError?.call('Failed to get daily steps for range: $e');
      log(
        'Get daily steps range error',
        name: 'PedometerService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Refresh all step counts manually
  Future<void> refreshAllStepCounts() async {
    if (!_isInitialized) {
      log(
        'Cannot refresh - service not initialized',
        name: 'PedometerService',
      );
      return;
    }

    try {
      await _loadInitialStepCounts();
      log('All step counts refreshed manually', name: 'PedometerService');
    } catch (e, stackTrace) {
      onError?.call('Failed to refresh step counts: $e');
      log(
        'Refresh error',
        name: 'PedometerService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Dispose all streams and clean up
  void dispose() {
    _stepStreamSubscription?.cancel();
    _stepStreamFromSubscription?.cancel();
    _pedestrianStatusSubscription?.cancel();

    _stepStreamSubscription = null;
    _stepStreamFromSubscription = null;
    _pedestrianStatusSubscription = null;

    _isInitialized = false;

    log('Pedometer service disposed', name: 'PedometerService');
  }

  /// Restart the pedometer service
  Future<void> restart() async {
    log('Restarting pedometer service', name: 'PedometerService');
    dispose();
    await initializePedometer();
  }

  /// Check if pedometer is available on the device
  Future<bool> isPedometerAvailable() async {
    try {
      // Try to get a step count to check availability
      await Pedometer().getStepCount(
        from: DateTime.now().subtract(const Duration(hours: 1)),
        to: DateTime.now(),
      );
      return true;
    } catch (e) {
      log(
        'Pedometer not available',
        name: 'PedometerService',
        error: e,
      );
      return false;
    }
  }

  /// Reset daily steps at midnight (call this from a background task)
  Future<void> resetDailyStepsIfNeeded() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    // If we've crossed midnight, refresh counts
    if (now.difference(midnight).inMinutes < 5) {
      log('Midnight detected, resetting daily steps', name: 'PedometerService');
      await refreshAllStepCounts();
    }
  }
}
