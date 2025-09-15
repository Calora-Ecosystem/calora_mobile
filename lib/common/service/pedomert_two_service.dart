import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:pedometer_2/pedometer_2.dart';
import 'package:permission_handler/permission_handler.dart';

class PedometerService {
  // Current step data
  int? stepCount;
  int? stepCountStream;
  PedestrianStatus? pedestrianStatus;

  // For Android step counting
  int? _androidInitialStepCount;
  DateTime? _lastUpdateTime;

  // Stream subscriptions
  StreamSubscription<int>? _stepStreamSubscription;
  StreamSubscription<int>? _stepStreamFromSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;

  // Date range for step counting
  DateTime get _startOfWeek {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1));
  }

  DateTime get _endOfWeek {
    final now = DateTime.now();
    return now.add(Duration(days: DateTime.daysPerWeek - now.weekday));
  }

  // Callbacks for UI updates
  final ValueChanged<int>? onStepCountUpdated;
  final ValueChanged<PedestrianStatus>? onPedestrianStatusUpdated;
  final ValueChanged<String>? onError;

  PedometerService({
    this.onStepCountUpdated,
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
      // Get historical step count
      await _getHistoricalStepCount();

      // Start listening to real-time streams
      _listenToStepCountStream();
      _listenToPedestrianStatusStream();

      // For iOS, listen to step count from specific date
      if (Platform.isIOS) {
        _listenToStepCountStreamFrom();
      }

      log('Pedometer service initialized successfully');
    } catch (e) {
      onError?.call('Failed to initialize pedometer: $e');
      rethrow;
    }
  }

  /// Get historical step count for the current week
  Future<void> _getHistoricalStepCount() async {
    try {
      stepCount = await Pedometer().getStepCount(
        from: _startOfWeek,
        to: _endOfWeek,
      );

      log('Historical step count: $stepCount');
      onStepCountUpdated?.call(stepCount ?? 0);
    } catch (e) {
      onError?.call('Failed to get historical step count: $e');
    }
  }

  /// Listen to real-time step count stream
  void _listenToStepCountStream() {
    try {
      _stepStreamSubscription = Pedometer().stepCountStream().listen(
        (int steps) {
          stepCountStream = steps;

          // For Android, calculate steps since service start
          if (Platform.isAndroid && _androidInitialStepCount == null) {
            _androidInitialStepCount = steps;
            _lastUpdateTime = DateTime.now();
          }

          log('Real-time step count: $steps');
          onStepCountUpdated?.call(steps);
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
  void _listenToStepCountStreamFrom() {
    if (!Platform.isIOS) return;

    try {
      _stepStreamFromSubscription = Pedometer()
          .stepCountStreamFrom(from: _startOfWeek)
          .listen(
            (int steps) {
              stepCount = steps;
              log('Step count from start of week: $steps');
              onStepCountUpdated?.call(steps);
            },
            onError: (error) {
              onError?.call('Step count from stream error: $error');
            },
            cancelOnError: false,
          );
    } catch (e) {
      onError?.call('Failed to listen to step count from stream: $e');
    }
  }

  /// Listen to pedestrian status stream
  void _listenToPedestrianStatusStream() {
    try {
      _pedestrianStatusSubscription = Pedometer()
          .pedestrianStatusStream()
          .listen(
            (PedestrianStatus status) {
              pedestrianStatus = status;
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

  /// Get today's steps
  Future<int> getTodaysSteps() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    return await getStepsForDateRange(todayStart, todayEnd);
  }

  /// Get steps from the past 24 hours
  Future<int> getStepsPast24Hours() async {
    try {
      final now = DateTime.now();
      final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));

      log('Getting steps from past 24 hours: $twentyFourHoursAgo to $now');

      final steps = await Pedometer().getStepCount(
        from: twentyFourHoursAgo,
        to: now,
      );

      log('Steps in past 24 hours: $steps');
      return steps;
    } catch (e) {
      onError?.call('Failed to get steps from past 24 hours: $e');
      rethrow;
    }
  }

  /// Get steps from a specific hour range (e.g., last 1, 6, 12 hours)
  Future<int> getStepsForHourRange(int hours) async {
    try {
      final now = DateTime.now();
      final startTime = now.subtract(Duration(hours: hours));

      log('Getting steps from last $hours hours: $startTime to $now');

      final steps = await Pedometer().getStepCount(from: startTime, to: now);

      log('Steps in last $hours hours: $steps');
      return steps;
    } catch (e) {
      onError?.call('Failed to get steps for $hours hour range: $e');
      rethrow;
    }
  }

  /// Get weekly steps
  Future<int> getWeeklySteps() async {
    return await getStepsForDateRange(_startOfWeek, _endOfWeek);
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
}
