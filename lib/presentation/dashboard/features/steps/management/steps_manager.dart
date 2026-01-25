import 'dart:async';
import 'dart:developer';

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

  StepsManager(this.stepRepo)
    : super(
        StepsState(
          dailyFrom: DateTime.now().toIso8601String(),
          dailyTo: DateTime.now().toIso8601String(),
          dailyUserStates: [],
          weeklyUserStates: [],
          monthlyUserStates: [],
        ),
      );

  void updateTodaySteps(int steps) {
    emit(state.copyWith(stepCount: steps));

    if (state.period == 0 && state.dailyOffset == 0) {
      emit(state.copyWith(dailyDisplayStepCount: steps));
    }
  }

  Future<void> getSteps({required int period, required int offset, required DateTime now}) async {
    await stepRepo
        .getSteps(period, offset: offset)
        .handle(
          onStart: () => emit(state.copyWith(isGettingSteps: true)),
          onData: (data) {
            if (period == 0) {
              final displayStepCount = offset == 0 ? state.stepCount : _buildDailySteps(data, offset, now);
              emit(
                state.copyWith(
                  dailySteps: data,
                  dailyDisplayStepCount: displayStepCount,
                  isGettingSteps: false,
                ),
              );
            } else if (period == 1) {
              final primaryValues = _buildWeeklySteps(data, offset, now);
              emit(
                state.copyWith(
                  weeklySteps: data,
                  weeklyPrimaryValues: primaryValues,
                  isGettingSteps: false,
                ),
              );
            } else if (period == 2) {
              final primaryValues = _buildMonthlySteps(data, offset, now);
              emit(state.copyWith(monthlySteps: data, monthlyPrimaryValues: primaryValues, isGettingSteps: false));
            }
          },
          onDone: () => emit(state.copyWith(isGettingSteps: false)),
          onError: (e) => emit(state.copyWith(isGettingSteps: false)),
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

  Future<void> getUserMetrics({required int period, required int offset, required DateTime now}) async {
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

    final from = fromDate.toIso8601String();
    final to = toDate.toIso8601String();

    await stepRepo
        .getUserMetrics(from: from, to: to)
        .handle(
          onStart: () => emit(state.copyWith(isGettingUserMetrics: true)),
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

  Future<void> fetchDataForPeriod(int period, int offset, {bool refresh = false}) async {
    final now = DateTime.now();

    if (period == 0) {
      emit(state.copyWith(isDailyLoading: true));
    } else if (period == 1) {
      emit(state.copyWith(isWeeklyLoading: true));
    } else if (period == 2) {
      emit(state.copyWith(isMonthlyLoading: true));
    }

    await Future.wait([
      _safeTrigger(getNorms),
      _safeTrigger(() => getSteps(period: period, offset: offset, now: now)),
      _safeTrigger(() => getStats(period: period, offset: offset, now: now)),
      _safeTrigger(() => getUserMetrics(period: period, offset: offset, now: now)),
    ]);

    if (period == 0) {
      emit(state.copyWith(isDailyLoading: false));
    } else if (period == 1) {
      emit(state.copyWith(isWeeklyLoading: false));
    } else if (period == 2) {
      emit(state.copyWith(isMonthlyLoading: false));
    }
  }

  Future<void> _safeTrigger(Future<void> Function() task) async {
    try {
      await task();
    } catch (e, s) {
      log(e.toString() + s.toString());
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

  Future<void> deleteNorm(String metric) async {
    await stepRepo
        .deleteNorm(metric)
        .handle(
          onStart: () => emit(state.copyWith(isDeletingNorm: true)),
          onData: (_) => getNorms(),
          onDone: () => emit(state.copyWith(isDeletingNorm: false)),
          onError: (_) => emit(state.copyWith(isDeletingNorm: false)),
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
  }

  void changeOffset(int change) {
    int currentOffset;
    int newOffset;
    final DateTime now = DateTime.now();
    DateTime fromDate;
    DateTime toDate;

    switch (state.period) {
      case 0:
        currentOffset = state.dailyOffset;
        newOffset = currentOffset + change;
        if (change > 0 && newOffset > 0) return;
        if (newOffset == currentOffset) return;

        final targetDay = now.add(Duration(days: newOffset));
        fromDate = DateTime(targetDay.year, targetDay.month, targetDay.day);
        toDate = DateTime(targetDay.year, targetDay.month, targetDay.day, 23, 59, 59);

        emit(
          state.copyWith(
            dailyOffset: newOffset,
            dailyFrom: fromDate.toIso8601String(),
            dailyTo: toDate.toIso8601String(),
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
        fromDate = DateTime(startOfTargetWeek.year, startOfTargetWeek.month, startOfTargetWeek.day);
        final endOfTargetWeek = startOfTargetWeek.add(const Duration(days: 6));
        toDate = DateTime(endOfTargetWeek.year, endOfTargetWeek.month, endOfTargetWeek.day, 23, 59, 59);

        emit(
          state.copyWith(
            weeklyOffset: newOffset,
            weeklyFrom: fromDate.toIso8601String(),
            weeklyTo: toDate.toIso8601String(),
          ),
        );
        break;
      case 2:
        currentOffset = state.monthlyOffset;
        newOffset = currentOffset + change;
        if (change > 0 && newOffset > 0) return;
        if (newOffset == currentOffset) return;

        final targetMonth = DateTime(now.year, now.month + newOffset);
        fromDate = DateTime(targetMonth.year, targetMonth.month);
        final endOfMonth = DateTime(targetMonth.year, targetMonth.month + 1, 0);
        toDate = DateTime(endOfMonth.year, endOfMonth.month, endOfMonth.day, 23, 59, 59);

        emit(
          state.copyWith(
            monthlyOffset: newOffset,
            monthlyFrom: fromDate.toIso8601String(),
            monthlyTo: toDate.toIso8601String(),
          ),
        );
        break;
      default:
        return;
    }
    fetchDataForPeriod(state.period, newOffset);
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

  int _buildDailySteps(List<StepsWithMetricsRequest> data, int offset, DateTime now) {
    if (data.isEmpty) {
      if (offset == 0) return state.stepCount;
      return 0;
    }

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

    final List<double> week = List.filled(7, 0);

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

    final List<double> month = List.filled(daysInMonth, 0);

    for (final step in data) {
      if (step.date.year == targetMonth.year && step.date.month == targetMonth.month) {
        final dayIndex = step.date.day - 1;
        if (dayIndex >= 0 && dayIndex < daysInMonth) month[dayIndex] = step.value;
      }
    }

    return month;
  }
}
