import 'dart:developer';

import 'package:calora/common/base/step_ledger_store.dart';
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

    return _mergeWithHealthHistory(response, from, to);
  }

  /// Merges the backend daily-step history with Health Connect's per-day
  /// history, taking `max(health, backend)` for each day — so a day the
  /// backend missed (e.g. the app was closed) still shows the steps Health
  /// Connect recorded, and vice-versa. If Health is unavailable (or
  /// unpermitted on Android) it returns the backend data unchanged. iOS is
  /// treated as optimistically permitted (HealthKit hides read status).
  Future<List<StepsWithMetricsRequest>> _mergeWithHealthHistory(
    List<StepsWithMetricsRequest> backend,
    DateTime from,
    DateTime to,
  ) async {
    try {
      if (!await isHealthDataAvailable()) return backend;
      if (defaultTargetPlatform != TargetPlatform.iOS) {
        if (!await hasHealthPermission()) return backend;
      }

      final now = DateTime.now();
      final startDay = DateTime(from.year, from.month, from.day);
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      var endExclusive = DateTime(to.year, to.month, to.day).add(const Duration(days: 1));
      if (endExclusive.isAfter(tomorrow)) endExclusive = tomorrow; // no future
      if (!endExclusive.isAfter(startDay)) return backend;

      // ONE bucketed-aggregate call for the whole range instead of up to
      // 31 sequential reads. `getHealthIntervalDataFromTypes` with a
      // 1-day (86400s) interval uses Health Connect's
      // aggregateGroupByDuration — i.e. the AGGREGATE, so Samsung Health
      // is included (a per-record query would miss it).
      final hcByDay = <String, int>{};
      try {
        final points = await _health.getHealthIntervalDataFromTypes(
          startDate: startDay,
          endDate: endExclusive,
          types: const [HealthDataType.STEPS],
          interval: 86400,
        );
        for (final p in points) {
          final v = p.value;
          if (v is! NumericHealthValue) continue;
          final steps = v.numericValue.round();
          if (steps <= 0) continue;
          final key = _dayKeyOf(p.dateFrom.toLocal());
          if (steps > (hcByDay[key] ?? 0)) hcByDay[key] = steps;
        }
      } catch (e) {
        log('[Health] bucketed aggregate failed, using backend only: $e');
        return backend;
      }

      if (hcByDay.isEmpty) return backend;

      // Merge: max(health, backend) per day.
      final byDay = <String, StepsWithMetricsRequest>{};
      for (final e in backend) {
        byDay[_dayKeyOf(e.date)] = e;
      }
      hcByDay.forEach((key, hc) {
        final existing = byDay[key];
        final backendVal = existing?.value.toInt() ?? 0;
        if (hc > backendVal) {
          byDay[key] = (existing ??
                  StepsWithMetricsRequest(date: DateTime.parse(key), value: 0))
              .copyWith(value: hc.toDouble());
        }
      });

      final merged = byDay.values.toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      return merged;
    } catch (e) {
      log('[Health] history merge failed, using backend only: $e');
      return backend;
    }
  }

  String _dayKeyOf(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

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
  Future<void> sendDailyData({
    required String metric,
    required int value,
    DateTime? date,
  }) =>
      _stepsApi.sendDailyData(metric: metric, value: value, date: date);

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
      // iOS HealthKit hides read-permission status (Apple privacy
      // model), so `hasHealthPermission()` returns false on iOS even
      // after grant. We gate only on Android (Health Connect) and
      // probe the store directly on iOS — a missing permission just
      // returns null from `getTotalStepsInInterval` below, which we
      // already coalesce to 0.
      if (defaultTargetPlatform != TargetPlatform.iOS) {
        if (!await hasHealthPermission()) return;
      }

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
          final value = await _stepsInInterval(dayStart, dayEnd);
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
  List<StepsWithMetricsRequest> getLast30DaysLocal() {
    final ledger = StepLedgerStore();
    return ledger
        .getLast30Days()
        .map((e) => StepsWithMetricsRequest(
              date: e.key,
              value: e.value.toDouble(),
            ))
        .toList();
  }

  @override
  Future<int> getTodayHealthSteps() async {
    try {
      final authorized = await ensureHealthAuthorized();
      if (!authorized) return 0;

      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      final steps = await _stepsInInterval(midnight, now);
      log('[Health] Today\'s steps (deduped): $steps');

      return steps;
    } catch (e) {
      log('Error getting today health steps: $e');
      return 0;
    }
  }

  /// Reads the step total in [start, end] via Health Connect's native
  /// aggregate ([Health.getTotalStepsInInterval]).
  ///
  /// Health Connect's aggregate de-duplicates overlapping records across
  /// source apps using its data-origin priority, so it returns one
  /// coherent number that includes Samsung Health, Google Fit and the
  /// platform provider — without double-counting.
  ///
  /// NB: we deliberately do NOT read raw records and de-dupe in Dart.
  /// That approach returned 0 for Samsung Health on real devices —
  /// Samsung's step records are not reliably visible to the per-record
  /// query (`getHealthDataFromTypes`) even when they ARE included in the
  /// aggregate. The aggregate is the only dependable read.
  Future<int> _stepsInInterval(DateTime start, DateTime end) async {
    final now = DateTime.now();
    final cappedEnd = end.isAfter(now) ? now : end;
    if (!cappedEnd.isAfter(start)) return 0;

    try {
      final steps = await _health.getTotalStepsInInterval(start, cappedEnd);
      return steps ?? 0;
    } catch (e) {
      log('[Health] getTotalStepsInInterval failed for '
          '${start.toIso8601String()}–${cappedEnd.toIso8601String()}: $e');
      return 0;
    }
  }

  @override
  Future<int> getHealthStepsForDay(DateTime day) async {
    try {
      // iOS's HealthKit doesn't surface read-permission status, so
      // `ensureHealthAuthorized` is unreliable there. Skip the gate
      // and probe the store directly — if permission is actually
      // missing the underlying call returns null which we coerce to 0.
      if (defaultTargetPlatform != TargetPlatform.iOS) {
        final authorized = await ensureHealthAuthorized();
        if (!authorized) return 0;
      }

      final start = DateTime(day.year, day.month, day.day);
      final end = DateTime(day.year, day.month, day.day, 23, 59, 59);

      final steps = await _stepsInInterval(start, end);
      log('[Health] Steps for ${start.toIso8601String()}: $steps');
      return steps;
    } catch (e) {
      log('Error getting health steps for day: $e');
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

    // Cap `to` at end-of-today so the API window never includes future
    // dates. Without this the monthly view requests e.g. 2026-05-01 →
    // 2026-05-31 even when today is 2026-05-19, and the server dutifully
    // returns 0-step rows for May 20–31 that the chart then renders as
    // empty bars after today's position.
    final endOfToday = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
      23,
      59,
      59,
    );
    if (to.isAfter(endOfToday)) {
      to = endOfToday;
    }

    return {'from': from, 'to': to};
  }

  @override
  Future<bool> deleteUserDailyData({required String date}) async {
    return await _stepsApi.deleteUserDailyData(date: date);
  }
}
