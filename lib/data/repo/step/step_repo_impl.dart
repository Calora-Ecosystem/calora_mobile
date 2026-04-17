import 'dart:developer';

import 'package:calora/data/api/steps_api.dart';
import 'package:calora/domain/model/dailies/steps_stat.dart';
import 'package:calora/domain/model/norms/norms.dart';
import 'package:calora/domain/model/pagination/paginated_response.dart';
import 'package:calora/domain/model/step/metrics_request.dart';
import 'package:calora/domain/model/user/user_stat.dart';
import 'package:calora/domain/repo/step/step_repo.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: StepRepo)
class StepRepoImpl extends StepRepo {
  final StepsApi _stepsApi;
  final Health _health = Health();
  static bool _authorizationRequested = false;

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

  Future<bool> _requestAuthorization() async {
    if (_authorizationRequested) return true;

    try {
      final types = [
        HealthDataType.STEPS,
        HealthDataType.WEIGHT,
        HealthDataType.HEART_RATE,
      ];
      final permissions = types.map((e) => HealthDataAccess.READ).toList();

      final bool? hasPermissions = await _health.hasPermissions(types, permissions: permissions);

      if (hasPermissions == true) {
        _authorizationRequested = true;
        return true;
      }

      final requested = await _health.requestAuthorization(types, permissions: permissions);
      _authorizationRequested = requested;
      return requested;
    } catch (e) {
      log('[Health] Error requesting authorization: $e');
      return false;
    }
  }

  @override
  Future<void> sendHealthData({required DateTime from, required DateTime to}) async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final status = await _health.getHealthConnectSdkStatus();
        if (status == HealthConnectSdkStatus.sdkUnavailable) return;
      }

      final authorized = await _requestAuthorization();
      if (!authorized) return;

      final types = [HealthDataType.STEPS];
      final healthData = await _health.getHealthDataFromTypes(
        startTime: from.toLocal(),
        endTime: to.toLocal(),
        types: types,
      );

      if (healthData.isNotEmpty) {
        final groupedByDate = groupBy(healthData, (HealthDataPoint p) {
          final date = p.dateFrom;
          return DateTime(date.year, date.month, date.day);
        });

        final List<StepsWithMetricsRequest> healthSteps = groupedByDate.entries
            .map((entry) {
              final date = entry.key;
              final totalSteps = entry.value.fold<int>(0, (sum, p) {
                final val = p.value;
                if (val is NumericHealthValue) {
                  return sum + val.numericValue.toInt();
                }
                return sum;
              });
              return StepsWithMetricsRequest(
                date: date,
                value: totalSteps.toDouble(),
              );
            })
            .where((element) => element.value > 0)
            .toList();

        if (healthSteps.isNotEmpty) {
          await _stepsApi.sendStepDataDateRange(steps: healthSteps);
          log('[Health] Successfully synced ${healthSteps.length} days of history.');
        }
      }
    } catch (e) {
      log('Error sending health data: $e');
    }
  }

  @override
  Future<int> getTodayHealthSteps() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final status = await _health.getHealthConnectSdkStatus();
        if (status == HealthConnectSdkStatus.sdkUnavailable) return 0;
      }

      final authorized = await _requestAuthorization();
      if (!authorized) return 0;

      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day).toLocal();

      final steps = await _health.getTotalStepsInInterval(midnight, now.toLocal());
      log('[Health] Today\'s total steps (aggregated): $steps');

      return steps ?? 0;
    } catch (e) {
      log('Error getting today health steps: $e');
    }
    return 0;
  }

  @override
  Future<bool> isHealthDataAvailable() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await _health.getHealthConnectSdkStatus();
      return status != HealthConnectSdkStatus.sdkUnavailable;
    }
    return true;
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
