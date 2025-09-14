import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:health/health.dart';

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
      log("HealthStep - Health Connect Status: $status");

      // Handle different status cases
      switch (status) {
        case HealthConnectSdkStatus.sdkUnavailable:
          log("HealthStep - Health Connect SDK is unavailable on this device");
          return;

        case HealthConnectSdkStatus.sdkAvailable:
          log("HealthStep - Health Connect is available and installed");
          break;

        default:
          log("HealthStep - Unknown Health Connect status: $status");
          break;
          // Simple method to get steps with automatic permission handling
          Future<int> getStepsWithAutoPermission() async {
            try {
              // Check and request permissions if needed
              bool hasPermissions = await hasStepPermissions();

              if (!hasPermissions) {
                log("HealthStep - No permissions, requesting...");
                bool granted = await requestStepPermissions();
                if (!granted) {
                  log("HealthStep - Permissions denied");
                  return 0;
                }
              }

              // Get today's steps
              return await fetchTodaySteps();
            } catch (e) {
              log("HealthStep - Error in getStepsWithAutoPermission: $e");
              return 0;
            }
          }
      }

      // Request permissions for steps
      await _requestStepPermissions();
    } catch (e) {
      log("HealthStep - Initialization error: $e");
    }
  }

  Future<void> _handleHealthConnectInstallation() async {
    try {
      log("HealthStep - Prompting user to install Health Connect...");

      final result = await health.installHealthConnect();
      log("HealthStep - Installation result:");
      log(
        "HealthStep - Please install Health Connect from Play Store and restart the app",
      );
    } catch (e) {
      log("HealthStep - Installation error: $e");
    }
  }

  Future<void> _requestStepPermissions() async {
    try {
      // Check if we already have step permissions
      bool hasStepPermissions =
          await health.hasPermissions(_stepDataTypes) ?? false;

      if (hasStepPermissions) {
        log("HealthStep - Already have step permissions");
        await fetchTodaySteps();
        return;
      }

      log("HealthStep - Requesting step permissions");

      // Request step authorization
      final granted = await health.requestAuthorization(_stepDataTypes);

      if (granted) {
        log("HealthStep - Step permissions granted successfully");
        await fetchTodaySteps();
      } else {
        log("HealthStep - Step permissions denied by user");
      }
    } catch (e) {
      log("HealthStep - Step permission request error: $e");
    }
  }

  // Get today's steps
  Future<int> fetchTodaySteps() async {
    try {
      var now = DateTime.now();
      var startOfLast24Hours = now.subtract(Duration(hours: 24));

      // Check permissions
      bool hasPermissions =
          await health.hasPermissions(_stepDataTypes) ?? false;
      if (!hasPermissions) {
        log("HealthStep - No step permissions");
        return 0;
      }

      List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(
        types: _stepDataTypes,
        startTime: startOfLast24Hours,
        endTime: now,
        recordingMethodsToFilter: recordingMethodsToFilter,
      );

      log("HealthStep - ResultDataPoint->${healthData.length}");

      int totalSteps = 0;
      for (var dataPoint in healthData) {
        if (dataPoint.value is NumericHealthValue) {
          int stepValue = (dataPoint.value as NumericHealthValue).numericValue
              .toInt();
          totalSteps += stepValue;
          log("HealthStep - Step entry: $stepValue at ${dataPoint.dateFrom}");
        }
      }

      log("HealthStep - Total steps in last 24 hours: $totalSteps");
      return totalSteps;
    } catch (e) {
      log("HealthStep - Error fetching last 24 hours steps: $e");
      return 0;
    }
  }

  // Get steps for last N days
  Future<Map<DateTime, int>> getStepsForDays(int numberOfDays) async {
    try {
      var now = DateTime.now();
      var startDate = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: numberOfDays - 1));

      bool hasPermissions =
          await health.hasPermissions(_stepDataTypes) ?? false;
      if (!hasPermissions) {
        log("HealthStep - No step permissions");
        return {};
      }

      List<HealthDataPoint> stepsData = await health.getHealthDataFromTypes(
        types: _stepDataTypes,
        startTime: startDate,
        endTime: now,
      );

      Map<DateTime, int> dailySteps = {};

      // Initialize all days with 0 steps
      for (int i = 0; i < numberOfDays; i++) {
        DateTime day = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: numberOfDays - 1 - i));
        dailySteps[day] = 0;
      }

      // Add actual step data
      for (var dataPoint in stepsData) {
        if (dataPoint.value is NumericHealthValue) {
          DateTime day = DateTime(
            dataPoint.dateFrom.year,
            dataPoint.dateFrom.month,
            dataPoint.dateFrom.day,
          );

          int steps = (dataPoint.value as NumericHealthValue).numericValue
              .toInt();
          dailySteps[day] = (dailySteps[day] ?? 0) + steps;
        }
      }

      // Log results
      dailySteps.forEach((date, steps) {
        log("HealthStep - ${date.day}/${date.month}: $steps steps");
      });

      return dailySteps;
    } catch (e) {
      log("HealthStep - Error getting steps for $numberOfDays days: $e");
      return {};
    }
  }

  // Get total steps for a specific date range
  Future<int> getTotalStepsInRange(DateTime startDate, DateTime endDate) async {
    try {
      bool hasPermissions =
          await health.hasPermissions(_stepDataTypes) ?? false;
      if (!hasPermissions) {
        log("HealthStep - No step permissions");
        return 0;
      }

      List<HealthDataPoint> stepsData = await health.getHealthDataFromTypes(
        types: _stepDataTypes,
        startTime: startDate,
        endTime: endDate,
      );

      int totalSteps = 0;
      for (var dataPoint in stepsData) {
        if (dataPoint.value is NumericHealthValue) {
          totalSteps += (dataPoint.value as NumericHealthValue).numericValue
              .toInt();
        }
      }

      log(
        "HealthStep - Total steps from ${startDate.day}/${startDate.month} to ${endDate.day}/${endDate.month}: $totalSteps",
      );
      return totalSteps;
    } catch (e) {
      log("HealthStep - Error getting total steps in range: $e");
      return 0;
    }
  }

  // Check if we have step permissions
  Future<bool> hasStepPermissions() async {
    try {
      return await health.hasPermissions(_stepDataTypes) ?? false;
    } catch (e) {
      log("HealthStep - Error checking permissions: $e");
      return false;
    }
  }

  // Manually request step permissions
  Future<bool> requestStepPermissions() async {
    try {
      return await health.requestAuthorization(_stepDataTypes);
    } catch (e) {
      log("HealthStep - Error requesting permissions: $e");
      return false;
    }
  }

  // Get Health Connect status
  Future<HealthConnectSdkStatus?> getHealthConnectStatus() async {
    try {
      return await health.getHealthConnectSdkStatus();
    } catch (e) {
      log("HealthStep - Error checking Health Connect status: $e");
      return null;
    }
  }

  // Simple method to get steps with automatic permission handling
  Future<int> getStepsWithAutoPermission() async {
    try {
      // Check and request permissions if needed
      bool hasPermissions = await hasStepPermissions();

      if (!hasPermissions) {
        log("HealthStep - No permissions, requesting...");
        bool granted = await requestStepPermissions();
        if (!granted) {
          log("HealthStep - Permissions denied");
          return 0;
        }
      }

      // Get today's steps
      return await fetchTodaySteps();
    } catch (e) {
      log("HealthStep - Error in getStepsWithAutoPermission: $e");
      return 0;
    }
  }
}
