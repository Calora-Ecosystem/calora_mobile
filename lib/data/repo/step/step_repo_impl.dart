import 'dart:developer';

import 'package:calora/common/service/installed_health_apps_service.dart';
import 'package:calora/data/api/steps_api.dart';
import 'package:calora/domain/model/dailies/steps_stat.dart';
import 'package:calora/domain/model/norms/norms.dart';
import 'package:calora/domain/model/pagination/paginated_response.dart';
import 'package:calora/domain/model/step/metrics_request.dart';
import 'package:calora/domain/model/user/user_stat.dart';
import 'package:calora/domain/repo/step/step_repo.dart';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';

@Injectable(as: StepRepo)
class StepRepoImpl extends StepRepo {
  final StepsApi _stepsApi;
  final Health _health = Health();

  bool _stepsAuthorized = false;

  bool _extendedAuthorized = false;

  StepRepoImpl(this._stepsApi) {
    _initHealth();
  }

  Future<void> _initHealth() async {
    try {
      if (!kIsWeb) {
        await _health.configure();
      }
    } catch (e) {
      log('Error configuring health: $e');
    }
  }

  @override
  Future<List<StepsWithMetricsRequest>> getSteps(
    int period, {
    int offset = 0,
    bool isSortDate = false,
  }) async {
    final take = period == 0
        ? 1
        : period == 1
        ? 7
        : 30;
    final skip = offset * take;

    final Map<String, DateTime> datePeriod = getDatePeriods(period, offset);
    final DateTime from = datePeriod['from']!;
    final DateTime to = datePeriod['to']!;

    final response = await _stepsApi.getSteps(
      metrics: 'Step',
      skip: skip,
      take: take,
      sortPropName: isSortDate ? 'date' : '',
      from: from,
      to: to,
    );

    return response;
  }

  @override
  Future<MetricsRequest> getUserMetrics({required String from, required String to}) async {
    final response = await _stepsApi.getUserMetrics(from: from, to: to);
    return response;
  }

  @override
  Future<PaginatedResponse<UserStatRequest>> getStats(
    int period, {
    int offset = 0,
    int skip = 0,
    int take = 20,
  }) async {
    final datePeriod = getDatePeriods(period, offset);
    final response = await _stepsApi.getStats(datePeriod['from']!, datePeriod['to']!, skip, take);
    return response;
  }

  @override
  Future<void> updateNorm(NormsRequest norm) => _stepsApi.updateNorm(norm);

  @override
  Future<void> sendDailyData({required String metric, required int value}) =>
      _stepsApi.sendDailyData(metric: metric, value: value);

  @override
  Future<void> sendStepDataDateRange({
    required List<StepsWithMetricsRequest> steps,
    DateTime? from,
    DateTime? to,
  }) async {
    if (steps.isNotEmpty) {
      await _stepsApi.sendStepDataDateRange(steps: steps);
    }

    if (from != null && to != null) {
      await sendHealthData(from: from, to: to);
    }
  }

  @override
  Future<bool> ensureHealthAuthorized() async {
    if (await hasHealthPermission()) return true;
    return requestHealthPermission();
  }

  @override
  Future<bool> hasHealthPermission() async {
    if (_stepsAuthorized) return true;

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final status = await _health.getHealthConnectSdkStatus();
        if (status != HealthConnectSdkStatus.sdkAvailable) {
          log('[Health] Health Connect unavailable: $status');
          return false;
        }
      }

      const types = [HealthDataType.STEPS];
      const permissions = [HealthDataAccess.READ];

      final already = await _health.hasPermissions(types, permissions: permissions);
      if (already == true) {
        _stepsAuthorized = true;
        return true;
      }
      return false;
    } catch (e) {
      log('[Health] hasHealthPermission error: $e');
      return false;
    }
  }

  @override
  Future<bool> requestHealthPermission() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final status = await _health.getHealthConnectSdkStatus();
        if (status != HealthConnectSdkStatus.sdkAvailable) {
          log('[Health] Health Connect unavailable on request: $status');
          return false;
        }
      }

      const types = [HealthDataType.STEPS];
      const permissions = [HealthDataAccess.READ];

      final granted = await _health.requestAuthorization(types, permissions: permissions);
      _stepsAuthorized = granted;
      return granted;
    } catch (e) {
      log('[Health] requestHealthPermission error: $e');
      return false;
    }
  }

  @override
  Future<void> openHealthSettings() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await InstalledHealthAppsService.openHealthConnectSettings();
      } else {
        await openAppSettings();
      }
    } catch (e) {
      log('[Health] openHealthSettings error: $e');
    }
  }

  Future<bool> _ensureExtendedAuthorized() async {
    if (_extendedAuthorized) return true;
    try {
      const types = [HealthDataType.WEIGHT, HealthDataType.HEART_RATE];
      final permissions = types.map((_) => HealthDataAccess.READ).toList();

      final already = await _health.hasPermissions(types, permissions: permissions);
      if (already == true) {
        _extendedAuthorized = true;
        return true;
      }

      final granted = await _health.requestAuthorization(types, permissions: permissions);
      _extendedAuthorized = granted;
      return granted;
    } catch (e) {
      log('[Health] _ensureExtendedAuthorized error: $e');
      return false;
    }
  }

  @override
  Future<void> sendHealthData({required DateTime from, required DateTime to}) async {
    try {
      if (!await hasHealthPermission()) return;

      final now = DateTime.now();
      // Never query the future — cap upper bound at "now".
      final cappedTo = to.isAfter(now) ? now : to;

      final startDay = DateTime(from.year, from.month, from.day);
      final endDay = DateTime(cappedTo.year, cappedTo.month, cappedTo.day);
      if (endDay.isBefore(startDay)) return;

      final List<StepsWithMetricsRequest> dailyTotals = [];

      DateTime cursor = startDay;
      while (!cursor.isAfter(endDay)) {
        final dayStart = DateTime(cursor.year, cursor.month, cursor.day);
        final isToday = dayStart.year == now.year &&
            dayStart.month == now.month &&
            dayStart.day == now.day;
        // For today, use "now" as upper bound. For past days, use end-of-day.
        final dayEnd = isToday
            ? now
            : DateTime(cursor.year, cursor.month, cursor.day, 23, 59, 59, 999);

        try {
          final steps = await _health.getTotalStepsInInterval(dayStart, dayEnd);
          final value = steps ?? 0;
          if (value > 0) {
            dailyTotals.add(
              StepsWithMetricsRequest(
                date: dayStart,
                value: value.toDouble(),
              ),
            );
          }
        } catch (e) {
          log('[Health] Aggregation failed for $dayStart: $e');
        }

        cursor = cursor.add(const Duration(days: 1));
      }

      if (dailyTotals.isNotEmpty) {
        await _stepsApi.sendStepDataDateRange(steps: dailyTotals);
        log('[Health] Synced ${dailyTotals.length} days of history '
            '(${dailyTotals.first.date.toIso8601String()} → '
            '${dailyTotals.last.date.toIso8601String()}).');
      }
    } catch (e) {
      log('Error sending health data: $e');
    }
  }

  @override
  Future<int> getTodayHealthSteps() async {
    try {
      final authorized = await ensureHealthAuthorized();
      if (!authorized) return 0;

      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day).toLocal();

      final steps = await _health.getTotalStepsInInterval(midnight, now.toLocal());
      log('[Health] Today\'s steps: $steps');

      return steps ?? 0;
    } catch (e) {
      log('Error getting today health steps: $e');
      return 0;
    }
  }

  @override
  Future<bool> isHealthDataAvailable() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final status = await _health.getHealthConnectSdkStatus();
        return status == HealthConnectSdkStatus.sdkAvailable;
      }
      return defaultTargetPlatform == TargetPlatform.iOS;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> deleteNorm(String metric) => _stepsApi.deleteNorm(metric);

  @override
  Future<List<NormsRequest>> getNorms() async => await _stepsApi.getNorms();

  Map<String, DateTime> getDatePeriods(int period, int offset, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();

    late DateTime from;
    late DateTime to;

    if (period == 0) {
      final today = DateTime(currentTime.year, currentTime.month, currentTime.day);
      from = today.add(Duration(days: offset));
      to = from.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
    } else if (period == 1) {
      final startOfWeek = currentTime.subtract(Duration(days: currentTime.weekday - 1));
      final weekStart = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day,
      );
      from = weekStart.add(Duration(days: 7 * offset));
      to = from.add(const Duration(days: 7)).subtract(const Duration(seconds: 1));
    } else {
      final startOfMonth = DateTime(currentTime.year, currentTime.month);
      from = DateTime(startOfMonth.year, startOfMonth.month + offset);
      to = DateTime(
        from.year,
        from.month + 1,
      ).subtract(const Duration(seconds: 1));
    }

    return {'from': from, 'to': to};
  }

  @override
  Future<bool> deleteUserDailyData({required String date}) async {
    return await _stepsApi.deleteUserDailyData(date: date);
  }
}
