import 'dart:io';

import 'package:health/health.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class HealthSyncService {
  final Health _health = Health();
  final List<HealthDataType> _stepTypes = [HealthDataType.STEPS];

  Future<void> init() async {
    await _health.configure();
  }

  Future<bool> requestPermission() async {
    try {
      if (Platform.isAndroid) {
        final bool isAvailable = await _health.isHealthConnectAvailable();
        if (!isAvailable) {
          return false;
        }
      }

      final bool? hasPermission = await _health.hasPermissions(_stepTypes);

      if (hasPermission != true) {
        return await _health.requestAuthorization(_stepTypes);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<int> getTotalSteps(DateTime start, DateTime end) async {
    try {
      final int? steps = await _health.getTotalStepsInInterval(start, end);
      return steps ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<Map<DateTime, int>> fetchMissingDays(int daysBack) async {
    final Map<DateTime, int> dailyMap = {};
    for (int i = 0; i < daysBack; i++) {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day - i);
      final end = DateTime(now.year, now.month, now.day - i, 23, 59, 59);

      final int steps = await getTotalSteps(start, end);
      if (steps > 0) dailyMap[start] = steps;
    }
    return dailyMap;
  }

  Future<int> getStepsForDay(DateTime day) async {
    try {
      final start = DateTime(day.year, day.month, day.day);
      final end = DateTime(day.year, day.month, day.day, 23, 59, 59);

      return await getTotalSteps(start, end);
    } catch (e) {
      return 0;
    }
  }
}
