import 'dart:async';
import 'dart:io';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class HealthDataService {
  // Callbacks for UI updates
  final ValueChanged<int> onStepCountUpdate;
  final ValueChanged<List<HealthDataPoint>> onHistoricalDataUpdate;
  final ValueChanged<bool> onPermissionUpdate;
  final ValueChanged<String> onError;

  // Health plugin instance
  final Health _health = Health();

  // State variables
  bool _permissionGranted = false;
  bool _isHealthAvailable = false;
  Timer? _dataFetchTimer;

  // Health data types we want to access
  static const List<HealthDataType> _healthDataTypes = [HealthDataType.STEPS];

  // Specify read access permissions
  static const List<HealthDataAccess> _permissions = [HealthDataAccess.READ];

  HealthDataService({
    required this.onStepCountUpdate,
    required this.onHistoricalDataUpdate,
    required this.onPermissionUpdate,
    required this.onError,
  });

  // Check if health data is available on the device
  Future<void> _checkHealthDataAvailability() async {
    try {
      _isHealthAvailable = await _health.requestAuthorization(_healthDataTypes);

      if (kDebugMode) {
        print('Health data available: $_isHealthAvailable');
      }
    } catch (e) {
      _isHealthAvailable = false;
      onError('Health data not available: ${e.toString()}');
    }
  }

  // Updated permission request method for Health Connect
  Future<bool> _requestHealthPermissions() async {
    try {
      if (kDebugMode) {
        print('Requesting health permissions...');
        print('Platform: ${Platform.operatingSystem}');
      }

      // For Android, check Health Connect availability first
      if (Platform.isAndroid) {
        // Check if Health Connect is installed
        final bool healthConnectAvailable = await _health.isDataTypeAvailable(
          HealthDataType.STEPS,
        );
        if (kDebugMode) {
          print('Health Connect available: $healthConnectAvailable');
        }

        if (!healthConnectAvailable) {
          onError(
            'Health Connect not available. Please install Google Health Connect from Play Store.',
          );
          return false;
        }
      }

      // Request authorization with explicit permissions
      final bool granted = await _health.requestAuthorization(
        _healthDataTypes,
        permissions: _permissions,
      );

      if (kDebugMode) {
        print('Health authorization result: $granted');
      }

      // For Android, also request activity recognition if needed
      if (Platform.isAndroid && granted) {
        var activityStatus = await Permission.activityRecognition.status;
        if (!activityStatus.isGranted) {
          activityStatus = await Permission.activityRecognition.request();
        }

        if (kDebugMode) {
          print('Activity recognition status: $activityStatus');
        }

        // Don't make this a hard requirement for Health Connect
        // granted = granted && activityStatus.isGranted;
      }

      return granted;
    } catch (e) {
      if (kDebugMode) {
        print('Health permission request error: $e');
      }
      onError('Health permission request error: $e');
      return false;
    }
  }

  // Enhanced initialization with Health Connect specific handling
  Future<void> initialize() async {
    try {
      if (kDebugMode) {
        print('Initializing HealthDataService...');
      }

      // Check if health data is supported on this platform
      if (Platform.isAndroid) {
        // For Android, verify Health Connect is available
        final bool available = await _health.isDataTypeAvailable(
          HealthDataType.STEPS,
        );
        if (!available) {
          onError(
            'Health data not supported. Please install and set up Google Health Connect.',
          );
          return;
        }
      }

      final granted = await _requestHealthPermissions();
      _permissionGranted = granted;
      onPermissionUpdate(granted);

      if (granted) {
        await _checkHealthDataAvailability();
        await fetchPast24HoursData();
        _startPeriodicDataFetch();
        if (kDebugMode) {
          print('HealthDataService initialized successfully');
        }
      } else {
        onError(
          'Health data permissions not granted. Please grant permissions in Health Connect settings.',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Initialization failed: $e');
      }
      onError('Initialization failed: ${e.toString()}');
    }
  }

  // Method to open Health Connect settings (Android)
  Future<void> openHealthConnectSettings() async {
    if (Platform.isAndroid) {
      try {
        // This will open Health Connect app for permission management
        await _health.requestAuthorization(
          _healthDataTypes,
          permissions: _permissions,
        );
      } catch (e) {
        onError('Failed to open Health Connect settings: $e');
      }
    }
  }

  // Enhanced debug method
  Future<void> debugPermissions() async {
    if (kDebugMode) {
      print('=== Health Permission Debug ===');
      print('Platform: ${Platform.operatingSystem}');

      try {
        // Check data type availability
        for (var type in _healthDataTypes) {
          final bool available = await _health.isDataTypeAvailable(type);
          print('$type available: $available');
        }

        // Check permissions
        final bool hasPermissions =
            await _health.hasPermissions(
              _healthDataTypes,
              permissions: _permissions,
            ) ??
            false;
        print('Has permissions: $hasPermissions');

        if (Platform.isAndroid) {
          final activityStatus = await Permission.activityRecognition.status;
          print('Activity recognition: $activityStatus');
        }
      } catch (e) {
        print('Debug error: $e');
      }
      print('=== End Debug ===');
    }
  }

  // Fetch step data from the past 24 hours
  Future<void> fetchPast24HoursData() async {
    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(hours: 24));

      if (kDebugMode) {
        print('Fetching data from $yesterday to $now');
      }

      // Fetch health data from the past 24 hours
      final List<HealthDataPoint> healthData = await _health
          .getHealthDataFromTypes(
            startTime: yesterday,
            endTime: now,
            types: _healthDataTypes,
          );

      if (kDebugMode) {
        print('Fetched ${healthData.length} health data points');
      }

      // Filter step data
      final List<HealthDataPoint> stepData = healthData
          .where((point) => point.type == HealthDataType.STEPS)
          .toList();

      // Calculate total steps
      int totalSteps = 0;
      for (var point in stepData) {
        if (point.value is NumericHealthValue) {
          totalSteps += (point.value as NumericHealthValue).numericValue
              .toInt();
        }
      }

      if (kDebugMode) {
        print('Total steps in past 24 hours: $totalSteps');
      }

      // Update UI with data
      onStepCountUpdate(totalSteps);
      onHistoricalDataUpdate(healthData);
    } catch (e) {
      onError('Failed to fetch past 24 hours data: ${e.toString()}');
    }
  }

  // Fetch hourly step data for the past 24 hours
  Future<List<Map<String, dynamic>>> getHourlyStepData() async {
    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(hours: 24));

      final List<Map<String, dynamic>> hourlyData = [];

      // Fetch data hour by hour for better granularity
      for (int i = 0; i < 24; i++) {
        final hourStart = yesterday.add(Duration(hours: i));
        final hourEnd = yesterday.add(Duration(hours: i + 1));

        final List<HealthDataPoint> hourData = await _health
            .getHealthDataFromTypes(
              startTime: hourStart,
              endTime: hourEnd,
              types: [HealthDataType.STEPS],
            );

        int hourSteps = 0;
        for (var point in hourData) {
          if (point.value is NumericHealthValue) {
            hourSteps += (point.value as NumericHealthValue).numericValue
                .toInt();
          }
        }

        hourlyData.add({'hour': hourStart, 'steps': hourSteps});
      }

      return hourlyData;
    } catch (e) {
      onError('Failed to fetch hourly data: ${e.toString()}');
      return [];
    }
  }

  // Start periodic data fetching (every 15 minutes)
  void _startPeriodicDataFetch() {
    _dataFetchTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      fetchPast24HoursData();
    });
  }

  // Get today's step count
  Future<int> getTodaysSteps() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final List<HealthDataPoint> todayData = await _health
          .getHealthDataFromTypes(
            types: [HealthDataType.STEPS],
            startTime: startOfDay,
            endTime: now,
          );

      int totalSteps = 0;
      for (var point in todayData) {
        if (point.value is NumericHealthValue) {
          totalSteps += (point.value as NumericHealthValue).numericValue
              .toInt();
        }
      }

      return totalSteps;
    } catch (e) {
      onError('Failed to fetch today\'s steps: ${e.toString()}');
      return 0;
    }
  }

  // Get step data for a specific date range
  Future<List<HealthDataPoint>> getStepDataForRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final List<HealthDataPoint> data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: start,
        endTime: end,
      );

      return data.where((point) => point.type == HealthDataType.STEPS).toList();
    } catch (e) {
      onError('Failed to fetch data for range: ${e.toString()}');
      return [];
    }
  }

  // Write step data (if supported by platform)
  // Future<bool> writeStepData(int steps, DateTime dateTime) async {
  //   try {
  //     return await _health.writeHealthData(
  //       steps.toDouble(),
  //       HealthDataType.STEPS,
  //       dateTime.subtract(const Duration(minutes: 1)),
  //       dateTime,
  //     );
  //   } catch (e) {
  //     onError('Failed to write step data: ${e.toString()}');
  //     return false;
  //   }
  // }

  // Request permission (can be called from UI)
  Future<void> requestPermission() async {
    try {
      final granted = await _requestHealthPermissions();
      _permissionGranted = granted;
      onPermissionUpdate(granted);

      if (granted) {
        await _checkHealthDataAvailability();
        await fetchPast24HoursData();
        _startPeriodicDataFetch();
      } else {
        onError(
          'Health data permissions denied. Please enable them in device settings to access step data from the past 24 hours.',
        );
      }
    } catch (e) {
      onError('Permission request failed: $e');
    }
  }

  // Check current permission status
  bool get isPermissionGranted => _permissionGranted;

  // Check if health data is available
  bool get isHealthAvailable => _isHealthAvailable;

  // Method to get detailed permission status
  Future<Map<String, bool>> getPermissionStatus() async {
    final Map<String, bool> status = {};

    try {
      status['health_data'] = await _health.requestAuthorization(
        _healthDataTypes,
      );

      if (Platform.isAndroid) {
        status['activity_recognition'] =
            await Permission.activityRecognition.isGranted;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking permission status: $e');
      }
    }

    return status;
  }

  // Dispose of resources
  void dispose() {
    _dataFetchTimer?.cancel();
  }
}
