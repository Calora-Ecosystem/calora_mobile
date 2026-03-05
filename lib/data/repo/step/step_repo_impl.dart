import 'dart:developer';
import 'dart:io';

import 'package:calora/data/api/steps_api.dart';
import 'package:calora/domain/model/dailies/steps_stat.dart';
import 'package:calora/domain/model/norms/norms.dart';
import 'package:calora/domain/model/pagination/paginated_response.dart';
import 'package:calora/domain/model/step/metrics_request.dart';
import 'package:calora/domain/model/user/user_stat.dart';
import 'package:calora/domain/repo/step/step_repo.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:health/health.dart';

@Injectable(as: StepRepo)
class StepRepoImpl extends StepRepo {
  final StepsApi _stepsApi;
  static bool _authorizationRequested = false;

  StepRepoImpl(this._stepsApi);

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

    log('GetSteps - period: $period, offset: $offset');
    log('From: ${from.toIso8601String()}, To: ${to.toIso8601String()}');

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
  Future<PaginatedResponse<UserStatRequest>> getStats(int period, {int offset = 0, int skip = 0, int take = 20}) async {
    log('ResultRepoImp: $period, $offset');
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

  Future<void> _requestAuthorization() async {
    if (_authorizationRequested) return;

    final health = Health();
    final types = [HealthDataType.STEPS,HealthDataType.WEIGHT,
      HealthDataType.HEART_RATE,];
    final permissions = [ HealthDataAccess.READ,
      HealthDataAccess.READ,
      HealthDataAccess.READ,];
    final requested = await health.requestAuthorization(types, permissions: permissions);
    log('[Health] Authorization requested: $requested');
    _authorizationRequested = true;
  }

  @override
  Future<void> sendHealthData({required DateTime from, required DateTime to}) async {
    try {
      final health = Health();
      if (defaultTargetPlatform == TargetPlatform.android) {
        final status = await health.getHealthConnectSdkStatus();
        log('[Health] Health Connect status: $status');
        if (status == HealthConnectSdkStatus.sdkUnavailable) {
          log('[Health] Health Connect is not available on this device.');
          return;
        }
        await _requestAuthorization();
      }

      final types = [HealthDataType.STEPS];
      final healthData = await health.getHealthDataFromTypes(startTime: from, endTime: to, types: types);
      log('[Health] Fetched ${healthData.length} health data points from $from to $to');

      if (healthData.isNotEmpty) {
        final groupedByDate = groupBy(healthData, (HealthDataPoint p) => DateTime(p.dateFrom.year, p.dateFrom.month, p.dateFrom.day));

        final healthSteps = groupedByDate.entries.map((entry) {
          final date = entry.key;
          final totalSteps = entry.value.fold<int>(0, (sum, p) => sum + (p.value as NumericHealthValue).numericValue.toInt());
          log('[Health] Date: $date, Total Steps: $totalSteps');
          return StepsWithMetricsRequest(
            date: date,
            value: totalSteps.toDouble(),
          );
        }).toList();

        await _stepsApi.sendStepDataDateRange(steps: healthSteps);
        log('[Health] Successfully sent ${healthSteps.length} aggregated health data points.');
      }
    } catch (e) {
      log('Error sending health data: $e');
    }
  }

  @override
  Future<int> getTodayHealthSteps() async {
    try {
      final health = Health();
      if (defaultTargetPlatform == TargetPlatform.android) {
        final status = await health.getHealthConnectSdkStatus();
        log('[Health] Health Connect status: $status');
        if (status == HealthConnectSdkStatus.sdkUnavailable) {
          log('[Health] Health Connect is not available on this device.');
          return 0;
        }
        await _requestAuthorization();
      }

      final types = [HealthDataType.STEPS];
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      final start = midnight.toLocal();
      final end = now.toLocal();

      final healthData = await health.getHealthDataFromTypes(startTime: start, endTime: end, types: types);
      log('[Health] Fetched ${healthData.length} health data points for today.$start');

      if (healthData.isNotEmpty) {
        final totalSteps = healthData.fold<int>(0, (sum, p) => sum + (p.value as NumericHealthValue).numericValue.toInt());
        log('[Health] Today\'s total steps: $totalSteps');
        return totalSteps;
      }
    } catch (e) {
      log('Error getting today health steps: $e');
    }
    return 0;
  }

  @override
  Future<bool> isHealthDataAvailable() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Health().getHealthConnectSdkStatus();
      return status != HealthConnectSdkStatus.sdkUnavailable;
    } else {
      // For iOS and other platforms, we assume health data is available
      return true;
    }
  }

  @override
  Future<void> deleteNorm(String metric) => _stepsApi.deleteNorm(metric);

  @override
  Future<List<NormsRequest>> getNorms() async => await _stepsApi.getNorms();

  Map<String, DateTime> getDatePeriods(int period, int offset, {DateTime? now}) {
    final now = DateTime.now();

    late DateTime from;
    late DateTime to;

    if (period == 0) {
      final today = DateTime(now.year, now.month, now.day);
      from = today.add(Duration(days: offset));
      to = from.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
    } else if (period == 1) {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final weekStart = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day,
      );
      from = weekStart.add(Duration(days: 7 * offset));
      to = from.add(const Duration(days: 7)).subtract(const Duration(seconds: 1));
    } else {
      final startOfMonth = DateTime(now.year, now.month);
      from = DateTime(startOfMonth.year, startOfMonth.month + offset);
      to = DateTime(
        from.year,
        from.month + 1,
      ).subtract(const Duration(seconds: 1));
    }

    log('Period: $period, Offset: $offset');
    log('From: ${from.toIso8601String()}, To: ${to.toIso8601String()}');

    return {'from': from, 'to': to};
  }

  @override
  Future<bool> deleteUserDailyData({required String date}) async {
    return await _stepsApi.deleteUserDailyData(date: date);
  }
}
