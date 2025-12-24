import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:health/health.dart';
import 'package:url_launcher/url_launcher.dart';

class HealthStepService {
  final Health health = Health();
  List<RecordingMethod> recordingMethodsToFilter = [];

  // Only STEPS data type
  static const List<HealthDataType> _stepDataTypes = [HealthDataType.STEPS];

  Future<void> initialize() async {
    try {
      await health.configure();

      // Check Health Connect status first
      final status = await health.getHealthConnectSdkStatus();
      log('HealthStep - Health Connect Status: $status');

      // Handle different status cases
      switch (status) {
        case HealthConnectSdkStatus.sdkUnavailable:
          log('HealthStep - Health Connect SDK is unavailable on this device');
          _showHealthConnectUnavailableMessage();
          return;

        case HealthConnectSdkStatus.sdkAvailable:
          log('HealthStep - Health Connect is available and installed');
          // Request permissions for steps
          await _requestStepPermissions();
          break;

        default:
          log('HealthStep - Unknown Health Connect status: $status');
          break;
      }
    } catch (e) {
      log('HealthStep - Initialization error: $e');
    }
  }

  void _showHealthConnectUnavailableMessage() {
    log(
      "HealthStep - This device doesn't support Health Connect. "
      'Minimum requirement: Android API level 26',
    );
  }

  Future<void> _handleHealthConnectInstallation() async {
    try {
      log('HealthStep - Prompting user to install/update Health Connect...');

      final result = await health.installHealthConnect();
      log('HealthStep - Installation prompt result: ');
    } catch (e) {
      log('HealthStep - Installation error: $e');
      await _openPlayStore();
    }
  }

  Future<void> _openPlayStore() async {
    try {
      const packageName = 'com.google.android.apps.healthdata';
      final playStoreUrl = 'market://details?id=$packageName';
      final webUrl =
          'https://play.google.com/store/apps/details?id=$packageName';

      if (await canLaunchUrl(Uri.parse(playStoreUrl))) {
        await launchUrl(Uri.parse(playStoreUrl));
      } else if (await canLaunchUrl(Uri.parse(webUrl))) {
        await launchUrl(Uri.parse(webUrl));
      } else {
        log(
          'HealthStep - Please install Health Connect from Play Store: $packageName',
        );
      }
    } catch (e) {
      log('HealthStep - Error opening Play Store: $e');
    }
  }

  Future<void> _requestStepPermissions() async {
    try {
      // Check if we already have step permissions
      final bool _hasStepPermissions = await hasStepPermissions();

      if (_hasStepPermissions) {
        log('HealthStep - Already have step permissions');
        return;
      }

      log('HealthStep - Requesting step permissions');

      // Request step authorization
      final granted = await requestStepPermissions();

      if (granted) {
        log('HealthStep - Step permissions granted successfully');
      } else {
        log('HealthStep - Step permissions denied by user');

        // Check if the denial was due to Health Connect issues
        final status = await getHealthConnectStatus();
        if (status == HealthConnectSdkStatus.sdkUnavailable) {
          await _handleHealthConnectInstallation();
        }
      }
    } catch (e) {
      log('HealthStep - Step permission request error: $e');

      // Check Health Connect status on error
      final status = await getHealthConnectStatus();
      if (status != HealthConnectSdkStatus.sdkAvailable) {
        await _handleHealthConnectInstallation();
      }
    }
  }

  // Get today's steps
  Future<int> fetchTodaySteps() async {
    try {
      final now = DateTime.now();
      final startOfLast24Hours = now.subtract(Duration(hours: 24));

      // Check permissions
      final bool hasPermissions = await hasStepPermissions();
      if (!hasPermissions) {
        log('HealthStep - No step permissions');
        return 0;
      }

      final List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(
        types: _stepDataTypes,
        startTime: startOfLast24Hours,
        endTime: now,
        recordingMethodsToFilter: recordingMethodsToFilter,
      );

      log('HealthStep - ResultDataPoint->${healthData.length}');

      int totalSteps = 0;
      for (var dataPoint in healthData) {
        if (dataPoint.value is NumericHealthValue) {
          final int stepValue = (dataPoint.value as NumericHealthValue).numericValue
              .toInt();
          totalSteps += stepValue;
          log('HealthStep - Step entry: $stepValue at ${dataPoint.dateFrom}');
        }
      }

      log('HealthStep - Total steps in last 24 hours: $totalSteps');
      return totalSteps;
    } catch (e) {
      log('HealthStep - Error fetching last 24 hours steps: $e');
      return 0;
    }
  }

  // Get steps for last N days
  Future<Map<DateTime, int>> getStepsForDays(int numberOfDays) async {
    try {
      final now = DateTime.now();
      final startDate = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: numberOfDays - 1));

      final bool hasPermissions = await hasStepPermissions();
      if (!hasPermissions) {
        log('HealthStep - No step permissions');
        return {};
      }

      final List<HealthDataPoint> stepsData = await health.getHealthDataFromTypes(
        types: _stepDataTypes,
        startTime: startDate,
        endTime: now,
      );

      final Map<DateTime, int> dailySteps = {};

      // Initialize all days with 0 steps
      for (int i = 0; i < numberOfDays; i++) {
        final DateTime day = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: numberOfDays - 1 - i));
        dailySteps[day] = 0;
      }

      // Add actual step data
      for (var dataPoint in stepsData) {
        if (dataPoint.value is NumericHealthValue) {
          final DateTime day = DateTime(
            dataPoint.dateFrom.year,
            dataPoint.dateFrom.month,
            dataPoint.dateFrom.day,
          );
          final int steps = (dataPoint.value as NumericHealthValue).numericValue
              .toInt();
          dailySteps[day] = (dailySteps[day] ?? 0) + steps;
        }
      }

      // Log results
      dailySteps.forEach((date, steps) {
        log('HealthStep - ${date.day}/${date.month}: $steps steps');
      });

      return dailySteps;
    } catch (e) {
      log('HealthStep - Error getting steps for $numberOfDays days: $e');
      return {};
    }
  }

  // Get total steps for a specific date range
  Future<int> getTotalStepsInRange(DateTime startDate, DateTime endDate) async {
    try {
      final bool hasPermissions = await hasStepPermissions();
      if (!hasPermissions) {
        log('HealthStep - No step permissions');
        return 0;
      }

      // Ensure proper time components - VERY IMPORTANT!
      final DateTime adjustedStartDate = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      );
      final DateTime adjustedEndDate = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
      );

      log(
        'HealthStep - Querying steps from $adjustedStartDate to $adjustedEndDate',
      );

      final List<HealthDataPoint> stepsData = await health.getHealthDataFromTypes(
        types: _stepDataTypes,
        startTime: adjustedStartDate,
        endTime: adjustedEndDate,
        recordingMethodsToFilter: [RecordingMethod.automatic],
      );

      log('HealthStep - Found ${stepsData.length} data points');

      int totalSteps = 0;
      for (var dataPoint in stepsData) {
        if (dataPoint.value is NumericHealthValue) {
          final int stepValue = (dataPoint.value as NumericHealthValue).numericValue
              .toInt();
          totalSteps += stepValue;
          log(
            'HealthStep - Data point: $stepValue steps at ${dataPoint.dateFrom} - ${dataPoint.dateTo}',
          );
        } else {
          log('HealthStep - Non-numeric value: ${dataPoint.value}');
        }
      }

      log(
        'HealthStep - Total steps from ${startDate.day}/${startDate.month}/${startDate.year} to ${endDate.day}/${endDate.month}/${endDate.year}: $totalSteps',
      );
      return totalSteps;
    } catch (e) {
      log('HealthStep - Error getting total steps in range: $e');
      return 0;
    }
  }

  // Check if we have step permissions
  Future<bool> hasStepPermissions() async {
    try {
      return await health.hasPermissions(_stepDataTypes) ?? false;
    } catch (e) {
      log('HealthStep - Error checking permissions: $e');
      return false;
    }
  }

  // Manually request step permissions
  Future<bool> requestStepPermissions() async {
    try {
      return await health.requestAuthorization(_stepDataTypes);
    } catch (e) {
      log('HealthStep - Error requesting permissions: $e');
      return false;
    }
  }

  // Get Health Connect status
  Future<HealthConnectSdkStatus?> getHealthConnectStatus() async {
    try {
      return await health.getHealthConnectSdkStatus();
    } catch (e) {
      log('HealthStep - Error checking Health Connect status: $e');
      return null;
    }
  }

  // Simple method to get steps with automatic permission handling
  Future<int> getStepsWithAutoPermission() async {
    try {
      // Check Health Connect status first
      final status = await getHealthConnectStatus();
      if (status != HealthConnectSdkStatus.sdkAvailable) {
        await _handleHealthConnectInstallation();
        return 0;
      }

      // Check and request permissions if needed
      final bool hasPermissions = await hasStepPermissions();

      if (!hasPermissions) {
        log('HealthStep - No permissions, requesting...');
        final bool granted = await requestStepPermissions();
        if (!granted) {
          log('HealthStep - Permissions denied');
          return 0;
        }
      }

      // Get today's steps
      return await fetchTodaySteps();
    } catch (e) {
      log('HealthStep - Error in getStepsWithAutoPermission: $e');
      return 0;
    }
  }

  // Check if device supports Health Connect
  Future<bool> isHealthConnectSupported() async {
    try {
      final status = await getHealthConnectStatus();
      return status == HealthConnectSdkStatus.sdkAvailable;
    } catch (e) {
      log('HealthStep - Error checking Health Connect support: $e');
      return false;
    }
  }

  // Get steps with comprehensive error handling
  Future<int> getStepsWithFallback() async {
    try {
      // Check if Health Connect is supported
      final isSupported = await isHealthConnectSupported();
      if (!isSupported) {
        log('HealthStep - Health Connect not supported on this device');
        return 0;
      }

      // Check Health Connect status
      final status = await getHealthConnectStatus();
      if (status != HealthConnectSdkStatus.sdkAvailable) {
        log(
          'HealthStep - Health Connect not available, prompting installation',
        );
        await _handleHealthConnectInstallation();
        return 0;
      }

      // Use the auto permission method
      return await getStepsWithAutoPermission();
    } catch (e) {
      log('HealthStep - Error in getStepsWithFallback: $e');
      return 0;
    }
  }

  // Fetch step data from the past 24 hours
  Future<void> fetchPast24HoursData() async {
    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(hours: 24));

      // Fetch health data from the past 24 hours
      final List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(
        startTime: yesterday,
        endTime: now,
        types: _stepDataTypes,
      );

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
      log('HealthStep Step->$totalSteps');
    } catch (e) {}
  }
}
