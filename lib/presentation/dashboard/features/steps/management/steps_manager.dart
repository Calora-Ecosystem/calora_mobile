import 'dart:async';
import 'dart:developer';

import 'package:calora/common/service/pedometer_service.dart';
import 'package:calora/common/widgets/stream/metrics_sync_bus.dart';
import 'package:calora/domain/model/dailies/steps_stat.dart';
import 'package:calora/domain/model/norms/norms.dart';
import 'package:calora/domain/repo/step/step_repo.dart';
import 'package:calora/presentation/dashboard/features/steps/management/steps_management.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class StepsManager extends Manager<StepsState, StepsEffect> {
  final StepRepo stepRepo;
  final PedometerService pedometerService;
  final MetricsSyncService _metricsSync;

  StreamSubscription<int>? _stepsSub;
  StreamSubscription? _syncSubscription;
  StreamSubscription<int>? _metricsSyncSub;

  Timer? _metricsSafetyTimer;
  Timer? _metricsDebounce;

  StepsManager(this.stepRepo, this.pedometerService, this._metricsSync)
    : super(
        StepsState(
          dailyFrom: DateTime.now().toIso8601String(),
          dailyTo: DateTime.now().toIso8601String(),
          dailyUserStates: [],
          weeklyUserStates: [],
          monthlyUserStates: [],
        ),
      );

  bool get _isTodayDailyView => state.period == 0 && state.dailyOffset == 0;

  @override
  void initialize() {
    super.initialize();
    _listenToMetricsSyncFromDashboard();
  }

  void _listenToMetricsSyncFromDashboard() {
    _syncSubscription?.cancel();

    _syncSubscription = _metricsSync.stream.listen((updatedSteps) {
      if (!_isTodayDailyView) return;
      log('StepsManager ← Dashboard sync bildirish: $updatedSteps qadam', name: 'StepsManager');
      _metricsDebounce?.cancel();
      _metricsDebounce = Timer(const Duration(milliseconds: 800), () {
        if (_isTodayDailyView) {
          log('StepsManager: today metrics silent refresh (sync tufayli)', name: 'StepsManager');
          getUserMetrics(period: 0, offset: 0, now: DateTime.now(), showLoading: false);
        }
      });
    });
  }

  void startLiveSyncIfNeeded() {
    if (_isTodayDailyView) {
      _startStepsListener();
      _listenToMetricsSyncFromDashboard();
      _startMetricsSafetyRefresh();
      _refreshTodayMetricsNow();
    } else {
      stopLiveSync();
    }
  }

  int get currentOffset {
    switch (state.period) {
      case 0:
        return state.dailyOffset;
      case 1:
        return state.weeklyOffset;
      case 2:
        return state.monthlyOffset;
      default:
        return 0;
    }
  }

  void stopLiveSync() {
    _stepsSub?.cancel();
    _stepsSub = null;

    _syncSubscription?.cancel();
    _syncSubscription = null;

    _metricsSyncSub?.cancel();
    _metricsSyncSub = null;

    _metricsDebounce?.cancel();
    _metricsDebounce = null;

    _metricsSafetyTimer?.cancel();
    _metricsSafetyTimer = null;
  }

  void _startStepsListener() {
    _stepsSub?.cancel();

    _stepsSub = pedometerService.todayStepsStream.listen(
      (steps) {
        if (!_isTodayDailyView) return;
        updateTodaySteps(steps);
      },
      onError: (e) => log('❌ Steps stream xatosi: $e', name: 'StepsManager'),
    );

    if (_isTodayDailyView) {
      updateTodaySteps(pedometerService.dailySteps);
    }
  }

  void _startMetricsSafetyRefresh() {
    _metricsSafetyTimer?.cancel();
    _metricsSafetyTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (_isTodayDailyView) {
        log('⏰ Safety refresh — metrics yangilanmoqda', name: 'StepsManager');
        _refreshTodayMetricsNow();
      }
    });
  }

  Future<void> _refreshTodayMetricsNow() async {
    await _safeTrigger(() => getUserMetrics(period: 0, offset: 0, now: DateTime.now()));
  }

  void updateTodaySteps(int steps) {
    emit(state.copyWith(stepCount: steps));

    if (_isTodayDailyView) emit(state.copyWith(dailyDisplayStepCount: steps));
  }

  Future<void> getSteps({required int period, required int offset, required DateTime now}) async {
    await stepRepo
        .getSteps(period, offset: offset)
        .handle(
          onStart: () => emit(state.copyWith(isGettingSteps: true)),
          onData: (data) {
            if (period == 0) {
              final displayStepCount = offset == 0 ? state.stepCount : _buildDailySteps(data, offset, now);

              emit(state.copyWith(dailySteps: data, dailyDisplayStepCount: displayStepCount, isGettingSteps: false));
            } else if (period == 1) {
              final primaryValues = _buildWeeklySteps(data, offset, now);
              emit(state.copyWith(weeklySteps: data, weeklyPrimaryValues: primaryValues, isGettingSteps: false));
            } else if (period == 2) {
              final primaryValues = _buildMonthlySteps(data, offset, now);
              emit(
                state.copyWith(
                  monthlySteps: data,
                  monthlyPrimaryValues: primaryValues,
                  isGettingSteps: false,
                ),
              );
            }
          },
          onDone: () => emit(state.copyWith(isGettingSteps: false)),
          onError: (_) => emit(state.copyWith(isGettingSteps: false)),
        );
  }

  Future<void> getStats({required int period, required int offset, required DateTime now}) async {
    await stepRepo
        .getStats(period, offset: offset)
        .handle(
          onStart: () => emit(state.copyWith(isGettingStats: true)),
          onData: (data) {
            if (period == 0) {
              emit(state.copyWith(dailyUserStates: data, isGettingStats: false));
            } else if (period == 1) {
              emit(state.copyWith(weeklyUserStates: data, isGettingStats: false));
            } else if (period == 2) {
              emit(state.copyWith(monthlyUserStates: data, isGettingStats: false));
            }
          },
          onDone: () => emit(state.copyWith(isGettingStats: false)),
          onError: (_) => emit(state.copyWith(isGettingStats: false)),
        );
  }

  Future<void> getUserMetrics({
    required int period,
    required int offset,
    required DateTime now,
    bool showLoading = true,
  }) async {
    final isTodayDaily = (period == 0 && offset == 0);
    DateTime fromDate;
    DateTime toDate;

    switch (period) {
      case 0:
        final targetDay = now.add(Duration(days: offset));
        fromDate = DateTime(targetDay.year, targetDay.month, targetDay.day);
        toDate = DateTime(targetDay.year, targetDay.month, targetDay.day, 23, 59, 59);
        break;
      case 1:
        final startOfCurrentWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfTargetWeek = startOfCurrentWeek.add(Duration(days: 7 * offset));
        fromDate = DateTime(startOfTargetWeek.year, startOfTargetWeek.month, startOfTargetWeek.day);
        final endOfTargetWeek = startOfTargetWeek.add(const Duration(days: 6));
        toDate = DateTime(endOfTargetWeek.year, endOfTargetWeek.month, endOfTargetWeek.day, 23, 59, 59);
        break;
      case 2:
        final targetMonth = DateTime(now.year, now.month + offset);
        fromDate = DateTime(targetMonth.year, targetMonth.month);
        final endOfMonth = DateTime(targetMonth.year, targetMonth.month + 1, 0);
        toDate = DateTime(endOfMonth.year, endOfMonth.month, endOfMonth.day, 23, 59, 59);
        break;
      default:
        return;
    }

    await stepRepo
        .getUserMetrics(from: fromDate.toIso8601String(), to: toDate.toIso8601String())
        .handle(
          onStart: () {
            final isTodayDaily = (period == 0 && offset == 0);
            if (showLoading && !isTodayDaily) emit(state.copyWith(isGettingUserMetrics: true));
          },
          onData: (data) {
            if (period == 0) {
              emit(state.copyWith(dailyMetrics: data, isGettingUserMetrics: false));
            } else if (period == 1) {
              emit(state.copyWith(weeklyMetrics: data, isGettingUserMetrics: false));
            } else if (period == 2) {
              emit(state.copyWith(monthlyMetrics: data, isGettingUserMetrics: false));
            }
          },
          onDone: () => emit(state.copyWith(isGettingUserMetrics: false)),
          onError: (_) => emit(state.copyWith(isGettingUserMetrics: false)),
        );
  }

  Future<void> fetchDataForPeriod(int period, int offset, {bool showLoading = false}) async {
    final now = DateTime.now();

    final isTodayDaily = (period == 0 && offset == 0);

    final shouldShowShimmer = showLoading && (!isTodayDaily || (isTodayDaily && !state.hasLoadedTodayInitial));

    if (shouldShowShimmer) {
      if (period == 0) emit(state.copyWith(isDailyLoading: true));
      if (period == 1) emit(state.copyWith(isWeeklyLoading: true));
      if (period == 2) emit(state.copyWith(isMonthlyLoading: true));
    }

    await Future.wait([
      _safeTrigger(getNorms),
      _safeTrigger(() => getSteps(period: period, offset: offset, now: now)),
      _safeTrigger(() => getStats(period: period, offset: offset, now: now)),
      _safeTrigger(() => getUserMetrics(period: period, offset: offset, now: now)),
    ]);

    if (period == 0) emit(state.copyWith(isDailyLoading: false));
    if (period == 1) emit(state.copyWith(isWeeklyLoading: false));
    if (period == 2) emit(state.copyWith(isMonthlyLoading: false));

    if (isTodayDaily && !state.hasLoadedTodayInitial) {
      emit(state.copyWith(hasLoadedTodayInitial: true));
    }

    startLiveSyncIfNeeded();
  }

  Future<void> _safeTrigger(Future<void> Function() task) async {
    try {
      await task();
    } catch (e, s) {
      log('Safe trigger xatosi: $e\n$s', name: 'StepsManager');
    }
  }

  Future<void> getNorms() async {
    await stepRepo.getNorms().handle(
      onStart: () => emit(state.copyWith(isGettingNorms: true)),
      onData: (data) => emit(state.copyWith(norms: data, isGettingNorms: false)),
      onDone: () => emit(state.copyWith(isGettingNorms: false)),
      onError: (_) => emit(state.copyWith(isGettingNorms: false)),
    );
  }

  Future<void> updateNorm(NormsRequest norm) async {
    await stepRepo
        .updateNorm(norm)
        .handle(
          onStart: () => emit(state.copyWith(isUpdatingNorm: true)),
          onData: (_) => getNorms(),
          onDone: () => emit(state.copyWith(isUpdatingNorm: false)),
          onError: (_) => emit(state.copyWith(isUpdatingNorm: false)),
        );
  }

  void changePeriod(int newPeriod) {
    final now = DateTime.now();
    DateTime fromDate;
    DateTime toDate;
    int targetOffset;

    switch (newPeriod) {
      case 0:
        targetOffset = state.dailyOffset;
        final targetDay = now.add(Duration(days: targetOffset));
        fromDate = DateTime(targetDay.year, targetDay.month, targetDay.day);
        toDate = DateTime(targetDay.year, targetDay.month, targetDay.day, 23, 59, 59);
        emit(
          state.copyWith(period: newPeriod, dailyFrom: fromDate.toIso8601String(), dailyTo: toDate.toIso8601String()),
        );
        break;
      case 1:
        targetOffset = state.weeklyOffset;
        final startOfCurrentWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfTargetWeek = startOfCurrentWeek.add(Duration(days: 7 * targetOffset));
        fromDate = DateTime(startOfTargetWeek.year, startOfTargetWeek.month, startOfTargetWeek.day);
        final endOfTargetWeek = startOfTargetWeek.add(const Duration(days: 6));
        toDate = DateTime(endOfTargetWeek.year, endOfTargetWeek.month, endOfTargetWeek.day, 23, 59, 59);
        emit(
          state.copyWith(period: newPeriod, weeklyFrom: fromDate.toIso8601String(), weeklyTo: toDate.toIso8601String()),
        );
        break;
      case 2:
        targetOffset = state.monthlyOffset;
        final targetMonth = DateTime(now.year, now.month + targetOffset);
        fromDate = DateTime(targetMonth.year, targetMonth.month);
        final endOfMonth = DateTime(targetMonth.year, targetMonth.month + 1, 0);
        toDate = DateTime(endOfMonth.year, endOfMonth.month, endOfMonth.day, 23, 59, 59);
        emit(
          state.copyWith(
            period: newPeriod,
            monthlyFrom: fromDate.toIso8601String(),
            monthlyTo: toDate.toIso8601String(),
          ),
        );
        break;
      default:
        return;
    }

    startLiveSyncIfNeeded();
  }

  void changeOffset(int change) {
    int currentOffset;
    int newOffset;
    final now = DateTime.now();

    switch (state.period) {
      case 0:
        currentOffset = state.dailyOffset;
        newOffset = currentOffset + change;
        if (change > 0 && newOffset > 0) return;
        if (newOffset == currentOffset) return;

        final targetDay = now.add(Duration(days: newOffset));
        emit(
          state.copyWith(
            dailyOffset: newOffset,
            dailyFrom: DateTime(targetDay.year, targetDay.month, targetDay.day).toIso8601String(),
            dailyTo: DateTime(targetDay.year, targetDay.month, targetDay.day, 23, 59, 59).toIso8601String(),
          ),
        );
        break;

      case 1:
        currentOffset = state.weeklyOffset;
        newOffset = currentOffset + change;
        if (change > 0 && newOffset > 0) return;
        if (newOffset == currentOffset) return;

        final startOfCurrentWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfTargetWeek = startOfCurrentWeek.add(Duration(days: 7 * newOffset));
        final endOfTargetWeek = startOfTargetWeek.add(const Duration(days: 6));

        emit(
          state.copyWith(
            weeklyOffset: newOffset,
            weeklyFrom: DateTime(
              startOfTargetWeek.year,
              startOfTargetWeek.month,
              startOfTargetWeek.day,
            ).toIso8601String(),
            weeklyTo: DateTime(
              endOfTargetWeek.year,
              endOfTargetWeek.month,
              endOfTargetWeek.day,
              23,
              59,
              59,
            ).toIso8601String(),
          ),
        );
        break;

      case 2:
        currentOffset = state.monthlyOffset;
        newOffset = currentOffset + change;
        if (change > 0 && newOffset > 0) return;
        if (newOffset == currentOffset) return;

        final targetMonth = DateTime(now.year, now.month + newOffset);
        final endOfMonth = DateTime(targetMonth.year, targetMonth.month + 1, 0);

        emit(
          state.copyWith(
            monthlyOffset: newOffset,
            monthlyFrom: DateTime(targetMonth.year, targetMonth.month).toIso8601String(),
            monthlyTo: DateTime(endOfMonth.year, endOfMonth.month, endOfMonth.day, 23, 59, 59).toIso8601String(),
          ),
        );
        break;

      default:
        return;
    }

    fetchDataForPeriod(state.period, newOffset, showLoading: true);
    startLiveSyncIfNeeded();
  }

  int _buildDailySteps(List<StepsWithMetricsRequest> data, int offset, DateTime now) {
    if (data.isEmpty) return offset == 0 ? state.stepCount : 0;

    final targetDate = DateTime(now.year, now.month, now.day).add(Duration(days: offset));
    final item = data.firstWhere(
      (e) => e.date.year == targetDate.year && e.date.month == targetDate.month && e.date.day == targetDate.day,
      orElse: () => StepsWithMetricsRequest(date: targetDate, value: 0),
    );

    return item.value.toInt();
  }

  List<double> _buildWeeklySteps(List<StepsWithMetricsRequest> data, int offset, DateTime now) {
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final targetWeekStart = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    ).add(Duration(days: 7 * offset));

    final week = List<double>.filled(7, 0);
    for (int i = 0; i < 7; i++) {
      final currentDay = DateTime(targetWeekStart.year, targetWeekStart.month, targetWeekStart.day + i);

      final item = data.firstWhere(
        (e) => e.date.year == currentDay.year && e.date.month == currentDay.month && e.date.day == currentDay.day,
        orElse: () => StepsWithMetricsRequest(date: currentDay, value: 0),
      );

      week[i] = item.value;
    }

    return week;
  }

  List<double> _buildMonthlySteps(List<StepsWithMetricsRequest> data, int offset, DateTime now) {
    final targetMonth = DateTime(now.year, now.month + offset);
    final daysInMonth = DateUtils.getDaysInMonth(targetMonth.year, targetMonth.month);

    final month = List<double>.filled(daysInMonth, 0);

    for (final step in data) {
      if (step.date.year == targetMonth.year && step.date.month == targetMonth.month) {
        final dayIndex = step.date.day - 1;
        if (dayIndex >= 0 && dayIndex < daysInMonth) month[dayIndex] = step.value;
      }
    }

    return month;
  }

  @override
  Future<void> close() {
    stopLiveSync();
    return super.close();
  }
}
