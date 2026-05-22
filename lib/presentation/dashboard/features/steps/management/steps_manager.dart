import 'dart:async';
import 'dart:developer';

import 'package:calora/common/service/pagination_service.dart';
import 'package:calora/common/service/pedometer_service.dart';
import 'package:calora/common/service/step_counter_service.dart';
import 'package:calora/domain/model/dailies/steps_stat.dart';
import 'package:calora/domain/model/norms/norms.dart';
import 'package:calora/domain/model/pagination/paginated_response.dart';
import 'package:calora/domain/model/pagination/pagination_query.dart';
import 'package:calora/domain/model/step/metrics_request.dart';
import 'package:calora/domain/model/user/user_stat.dart';
import 'package:calora/domain/repo/step/step_repo.dart';
import 'package:calora/presentation/dashboard/features/steps/management/steps_management.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class StepsManager extends Manager<StepsState, StepsEffect> {
  final StepRepo stepRepo;
  final PedometerService pedometerService;
  final StepCounterService _stepCounter;

  late final PaginationService<UserStatRequest> _dailyPaginationService;
  late final PaginationService<UserStatRequest> _weeklyPaginationService;
  late final PaginationService<UserStatRequest> _monthlyPaginationService;

  StreamSubscription<int>? _stepsSub;
  StreamSubscription? _syncSubscription;

  Timer? _metricsSafetyTimer;
  Timer? _metricsDebounce;

  Future<void>? _normsLoadingFuture;

  StepsManager(this.stepRepo, this.pedometerService, this._stepCounter)
    : super(StepsState(dailyFrom: DateTime.now().toIso8601String(), dailyTo: DateTime.now().toIso8601String())) {
    _initializePaginationServices();
    _listenToMetricsSyncFromDashboard();
  }

  bool get _isTodayDailyView => state.period == 0 && state.dailyOffset == 0;

  void _initializePaginationServices() {
    _dailyPaginationService = PaginationService<UserStatRequest>(
      fetchData: (query) => _fetchStatsForPeriod(0, state.dailyOffset, query),
    );
    _weeklyPaginationService = PaginationService<UserStatRequest>(
      fetchData: (query) => _fetchStatsForPeriod(1, state.weeklyOffset, query),
    );
    _monthlyPaginationService = PaginationService<UserStatRequest>(
      fetchData: (query) => _fetchStatsForPeriod(2, state.monthlyOffset, query),
    );
  }

  Future<PaginatedResponse<UserStatRequest>> _fetchStatsForPeriod(
    int period,
    int currentQueryOffset,
    PaginationQuery query,
  ) async {
    final effectiveOffset = period == 0
        ? state.dailyOffset
        : period == 1
        ? state.weeklyOffset
        : state.monthlyOffset;

    log(
      'PaginationService: _fetchStatsForPeriod called for period $period with effectiveOffset: $effectiveOffset, query skip: ${query.skip}',
      name: 'PaginationService',
    );

    return await stepRepo.getStats(period, offset: effectiveOffset, skip: query.skip ?? 0, take: query.take ?? 20);
  }

  PaginationService<UserStatRequest> get currentPaginationService {
    switch (state.period) {
      case 0:
        return _dailyPaginationService;
      case 1:
        return _weeklyPaginationService;
      case 2:
        return _monthlyPaginationService;
      default:
        return _dailyPaginationService;
    }
  }

  PaginationService<UserStatRequest> get dailyPaginationService => _dailyPaginationService;
  PaginationService<UserStatRequest> get weeklyPaginationService => _weeklyPaginationService;
  PaginationService<UserStatRequest> get monthlyPaginationService => _monthlyPaginationService;
  PagingController<int, UserStatRequest> get currentPagingController => currentPaginationService.pagingController;

  void refreshPagination() => currentPaginationService.refresh();
  void clearPaginationFilters() => currentPaginationService.clearFilters();

  void _listenToMetricsSyncFromDashboard() {
    _syncSubscription?.cancel();

    _syncSubscription = _stepCounter.stream.listen((updatedSteps) {
      if (!_isTodayDailyView) return;

      updateTodaySteps(updatedSteps);

      log('StepsManager ← Dashboard steps: $updatedSteps', name: 'StepsManager');

      _metricsDebounce?.cancel();
      _metricsDebounce = Timer(const Duration(milliseconds: 800), () {
        if (_isTodayDailyView) {
          getUserMetrics(period: 0, offset: 0, now: DateTime.now(), showLoading: false);
        }
      });
    });
  }

  void startLiveSyncIfNeeded() {
    if (_isTodayDailyView) {
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
    _syncSubscription?.cancel();
    _syncSubscription = null;

    _metricsDebounce?.cancel();
    _metricsDebounce = null;

    _metricsSafetyTimer?.cancel();
    _metricsSafetyTimer = null;
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
    await _safeTrigger(() => getUserMetrics(period: 0, offset: 0, now: DateTime.now()), '_refreshTodayMetricsNow');
  }

  void updateTodaySteps(int steps) {
    if (!_isTodayDailyView) return;
    if (steps <= 0 && state.stepCount > 0) return;
    if (steps == state.stepCount) return;
    emit(state.copyWith(stepCount: steps, dailyDisplayStepCount: steps));
  }

  Future<void> getSteps({
    required int period,
    required int offset,
    required DateTime now,
    bool showLoading = true,
  }) async {
    await stepRepo
        .getSteps(period, offset: offset)
        .handle(
          onStart: () {},
          onData: (data) {
            if (period == 0) {
              // Today (offset == 0) trusts the live count from
              // DashboardManager's Health/pedometer stream (mirrored
              // into state.stepCount via _listenToMetricsSyncFromDashboard).
              // Past days fall back to whatever the backend has for
              // that date — the 1-min sync + startup backfill keep
              // those values fresh.
              final displayStepCount = offset == 0 ? state.stepCount : _buildDailySteps(data, offset, now);
              emit(state.copyWith(dailySteps: data, dailyDisplayStepCount: displayStepCount, isGettingSteps: false));
            } else if (period == 1) {
              final primaryValues = _buildWeeklySteps(data, offset, now);
              emit(state.copyWith(weeklySteps: data, weeklyPrimaryValues: primaryValues, isGettingSteps: false));
            } else if (period == 2) {
              final primaryValues = _buildMonthlySteps(data, offset, now);
              emit(state.copyWith(monthlySteps: data, monthlyPrimaryValues: primaryValues, isGettingSteps: false));
            }
          },
          onDone: () => emit(state.copyWith(isGettingSteps: false)),
          onError: (_) => emit(state.copyWith(isGettingSteps: false)),
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

    // Never request future dates — the server happily echoes them back
    // as zero-step rows that show up as empty trailing bars.
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    if (toDate.isAfter(endOfToday)) toDate = endOfToday;

    await stepRepo
        .getUserMetrics(from: fromDate.toIso8601String(), to: toDate.toIso8601String())
        .handle(
          onStart: () {},
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

    if (showLoading || (isTodayDaily && !state.hasLoadedTodayInitial)) {
      if (period == 0) emit(state.copyWith(isDailyLoading: true));
      if (period == 1) emit(state.copyWith(isWeeklyLoading: true));
      if (period == 2) emit(state.copyWith(isMonthlyLoading: true));
    }

    try {
      final List<Future<void>> tasks = [];

      if (state.norms.isEmpty) {
        if (_normsLoadingFuture != null) {
          await _normsLoadingFuture;
        } else if (!state.isGettingNorms) {
          _normsLoadingFuture = _safeTrigger(() => getNorms(showLoading: showLoading), 'getNorms');
          tasks.add(_normsLoadingFuture!);
        }
      }

      bool areStepsPresent = false;
      switch (period) {
        case 0:
          areStepsPresent = state.dailySteps.isNotEmpty && state.dailyOffset == offset;
          break;
        case 1:
          areStepsPresent = state.weeklySteps.isNotEmpty && state.weeklyOffset == offset;
          break;
        case 2:
          areStepsPresent = state.monthlySteps.isNotEmpty && state.monthlyOffset == offset;
          break;
      }
      if (!areStepsPresent || showLoading) {
        tasks.add(
          _safeTrigger(() => getSteps(period: period, offset: offset, now: now, showLoading: showLoading), 'getSteps'),
        );
      }

      tasks.add(
        _safeTrigger(
          () => getUserMetrics(period: period, offset: offset, now: now, showLoading: false),
          'getUserMetrics',
        ),
      );
      if (showLoading) {
        log('StepsManager: Refreshing pagination for period $period', name: 'StepsManager');
        currentPaginationService.refresh();
      }
      await Future.wait(tasks);
    } finally {
      if (period == 0) emit(state.copyWith(isDailyLoading: false));
      if (period == 1) emit(state.copyWith(isWeeklyLoading: false));
      if (period == 2) emit(state.copyWith(isMonthlyLoading: false));
      if (isTodayDaily && !state.hasLoadedTodayInitial) emit(state.copyWith(hasLoadedTodayInitial: true));
    }

    startLiveSyncIfNeeded();
  }

  Future<void> _safeTrigger(Future<void> Function() task, String identifier) async {
    try {
      await task();
    } catch (e, s) {
      log(
        'StepsManager: Safe trigger xatosi for task $identifier: $e\n$s',
        name: 'StepsManager',
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<void> getNorms({bool showLoading = true}) async {
    emit(state.copyWith(isGettingNorms: true));
    await stepRepo.getNorms().handle(
      onStart: () {},
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
          state.copyWith(
            period: newPeriod,
            dailyFrom: fromDate.toIso8601String(),
            dailyTo: toDate.toIso8601String(),
          ),
        );
        fetchDataForPeriod(0, currentOffset);
        break;
      case 1:
        targetOffset = state.weeklyOffset;
        final startOfCurrentWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfTargetWeek = startOfCurrentWeek.add(Duration(days: 7 * targetOffset));
        fromDate = DateTime(startOfTargetWeek.year, startOfTargetWeek.month, startOfTargetWeek.day);
        final endOfTargetWeek = startOfTargetWeek.add(const Duration(days: 6));
        toDate = DateTime(endOfTargetWeek.year, endOfTargetWeek.month, endOfTargetWeek.day, 23, 59, 59);
        emit(
          state.copyWith(
            period: newPeriod,
            weeklyFrom: fromDate.toIso8601String(),
            weeklyTo: toDate.toIso8601String(),
          ),
        );
        fetchDataForPeriod(1, currentOffset);
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
        fetchDataForPeriod(2, currentOffset);
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

  bool _isMetricsRequestEmpty(MetricsRequest metrics) {
    return metrics.foots == 0 && metrics.distance == 0.0 && metrics.kcal == 0 && metrics.duration == 0;
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
    _dailyPaginationService.dispose();
    _weeklyPaginationService.dispose();
    _monthlyPaginationService.dispose();
    return super.close();
  }
}
