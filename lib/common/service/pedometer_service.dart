import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:pedometer_2/pedometer_2.dart';
import 'package:permission_handler/permission_handler.dart';

class PedometerService {
  // Stream subscriptions
  StreamSubscription<int>? _stepStreamSubscription;
  StreamSubscription<int>? _stepStreamFromSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;

  // Current step counts
  int _dailySteps = 0;
  int _weeklySteps = 0;
  int _monthlySteps = 0;

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
    return DateTime(
      now.year,
      now.month,
      1,
    ).copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
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

  // Callbacks for UI updates - SEPARATE callbacks for each time period
  final ValueChanged<int>? onTodayStepCountUpdated; // Only today's steps
  final ValueChanged<int>? onWeeklyStepCountUpdated;
  final ValueChanged<int>? onMonthlyStepCountUpdated;
  final ValueChanged<PedestrianStatus>? onPedestrianStatusUpdated;
  final ValueChanged<String>? onError;

  PedometerService({
    this.onTodayStepCountUpdated, // Only receives daily steps
    this.onWeeklyStepCountUpdated,
    this.onMonthlyStepCountUpdated,
    this.onPedestrianStatusUpdated,
    this.onError,
  });

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
      } else {
        onError?.call('Permission not granted: $permissionStatus');
        return false;
      }
    } catch (e) {
      onError?.call('Permission check failed: $e');
      return false;
    }
  }

  /// Initialize pedometer and start listening to streams
  Future<void> initializePedometer() async {
    try {
      // Load initial step counts
      await _loadInitialStepCounts();

      // Start listening to real-time streams
      _listenToStepCountStream();
      _listenToPedestrianStatusStream();

      // For iOS, listen to step count from specific date
      // if (Platform.isIOS) {
      //   _listenToStepCountStreamFrom();
      // }

      log('Pedometer service initialized successfully');
    } catch (e) {
      onError?.call('Failed to initialize pedometer: $e');
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
      );
    } catch (e) {
      onError?.call('Failed to load initial step counts: $e');
    }
  }

  /// Listen to real-time step count stream (for daily updates)
  void _listenToStepCountStream() {
    try {
      // Store the initial step count when stream starts
      int _lastStepCount = 0;
      bool _isInitialized = false;

      _stepStreamSubscription = Pedometer().stepCountStream().listen(
            (int steps) async {
          log('Real-time step count: $steps');

          if (!_isInitialized) {
            // First reading - get today's actual steps
            _dailySteps = await getTodaySteps();
            _lastStepCount = steps;
            _isInitialized = true;
            log('Initial daily steps: $_dailySteps');
          } else {
            // Calculate steps since last update
            int stepsSinceLastUpdate = steps - _lastStepCount;

            if (stepsSinceLastUpdate > 0) {
              // Add the new steps to today's total
              _dailySteps += stepsSinceLastUpdate;
              _lastStepCount = steps;
              log('Added $stepsSinceLastUpdate steps, Total today: $_dailySteps');
            }
          }

          onTodayStepCountUpdated?.call(_dailySteps);
        },
        onError: (error) {
          onError?.call('Step count stream error: $error');
        },
        cancelOnError: false,
      );
    } catch (e) {
      onError?.call('Failed to listen to step count stream: $e');
    }
  }
  /// Listen to step count stream from specific date (iOS only)
  // void _listenToStepCountStreamFrom() {
  //   if (!Platform.isIOS) return;
  //
  //   try {
  //     _stepStreamFromSubscription = Pedometer()
  //         .stepCountStreamFrom(from: _startOfWeek)
  //         .listen(
  //           (int steps) {
  //             log('Step count from start of week: $steps');
  //
  //             // Update weekly steps
  //             _weeklySteps = steps;
  //             onWeeklyStepCountUpdated?.call(_weeklySteps);
  //           },
  //           onError: (error) {
  //             onError?.call('Step count from stream error: $error');
  //           },
  //           cancelOnError: false,
  //         );
  //   } catch (e) {
  //     onError?.call('Failed to listen to step count from stream: $e');
  //   }
  // }

  /// Listen to pedestrian status stream
  void _listenToPedestrianStatusStream() {
    try {
      _pedestrianStatusSubscription = Pedometer()
          .pedestrianStatusStream()
          .listen(
            (PedestrianStatus status) {
              log('Pedestrian status: ${status}');
              onPedestrianStatusUpdated?.call(status);
            },
            onError: (error) {
              onError?.call('Pedestrian status stream error: $error');
            },
            cancelOnError: false,
          );
    } catch (e) {
      onError?.call('Failed to listen to pedestrian status stream: $e');
    }
  }

  /// Get steps for a custom date range
  Future<int> getStepsForDateRange(DateTime from, DateTime to) async {
    try {
      final steps = await Pedometer().getStepCount(from: from, to: to);
      log(
        'Steps from ${from.toIso8601String()} to ${to.toIso8601String()}: $steps',
      );
      return steps;
    } catch (e) {
      onError?.call('Failed to get steps for date range: $e');
      rethrow;
    }
  }

  /// Refresh all step counts manually
  Future<void> refreshAllStepCounts() async {
    try {
      await _loadInitialStepCounts();
      log('All step counts refreshed manually');
    } catch (e) {
      onError?.call('Failed to refresh step counts: $e');
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

    log('Pedometer service disposed');
  }

  /// Restart the pedometer service
  Future<void> restart() async {
    dispose();
    await initializePedometer();
  }

  /// Check if pedometer is available on the device
  static Future<bool> isPedometerAvailable() async {
    try {
      // Try to get a step count to check availability
      await Pedometer().getStepCount(
        from: DateTime.now().subtract(const Duration(hours: 1)),
        to: DateTime.now(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get weekly steps
  Future<int> getWeeklySteps() async {
    return await getStepsForDateRange(_startOfWeek, _endOfWeek);
  }

  Future<int> getTodaySteps() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    return await getStepsForDateRange(todayStart, todayEnd);
  }

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

      while (currentDate.isBefore(endDate) ||
          currentDate.isAtSameMomentAs(endDate)) {
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

        log('Steps for ${currentDate.toIso8601String().split('T')[0]}: $steps');

        // Move to next day
        currentDate = currentDate.add(const Duration(days: 1));
      }

      return dailySteps;
    } catch (e) {
      onError?.call('Failed to get daily steps for range: $e');
      rethrow;
    }
  }
}
