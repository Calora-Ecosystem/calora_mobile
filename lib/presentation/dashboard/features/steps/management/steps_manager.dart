import 'dart:async';

import 'package:calora/domain/model/dailies/steps_stat.dart';
import 'package:calora/domain/model/norms/norms.dart';
import 'package:calora/domain/model/step/metrics_request.dart';
import 'package:calora/domain/repo/step/step_repo.dart';
import 'package:calora/presentation/dashboard/features/steps/management/steps_management.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class StepsManager extends Manager<StepsState, StepsEffect> {
  final StepRepo stepRepo;
  Timer? _timer;

  StepsManager(this.stepRepo)
    : super(StepsState(from: DateTime.now().toIso8601String(), to: DateTime.now().toIso8601String()));

  void updateTodaySteps(int steps) {
    emit(state.copyWith(stepCount: steps));

    if (state.period == 0 && state.offset == 0) {
      emit(state.copyWith(displayStepCount: steps));
    }
  }

  void setMetricDates({String? from, String? to}) {
    emit(state.copyWith(from: from ?? state.from, to: to ?? state.to));
  }

  void start() {
    _timer = Timer.periodic(const Duration(hours: 1), (_) => sendDailyData());
    sendDailyData();
  }

  Future<void> getSteps() async {
    await stepRepo
        .getSteps(state.period, offset: state.offset)
        .handle(
          onStart: () => emit(state.copyWith(isGettingSteps: true)),
          onData: (data) {
            List<double> primaryValues = [];
            int? displayStepCount;

            if (state.period == 0) {
              if (state.offset == 0) {
                displayStepCount = state.stepCount;
              } else {
                displayStepCount = _buildDailySteps(data);
              }
            } else if (state.period == 1) {
              primaryValues = _buildWeeklySteps(data);
            } else if (state.period == 2) {
              primaryValues = _buildMonthlySteps(data);
            }
            if (displayStepCount != null) {
              emit(
                state.copyWith(
                  steps: data,
                  primaryValues: primaryValues,
                  displayStepCount: displayStepCount,
                  isGettingSteps: false,
                ),
              );
            } else {
              emit(state.copyWith(steps: data, primaryValues: primaryValues, isGettingSteps: false));
            }
          },
          onDone: () => emit(state.copyWith(isGettingSteps: false)),
          onError: (e) {
            emit(state.copyWith(isGettingSteps: false));
          },
        );
  }

  Future<void> getStats(int value) async {
    await stepRepo
        .getStats(state.period, offset: state.offset)
        .handle(
          onStart: () => emit(state.copyWith(isGettingStats: true)),
          onData: (data) => emit(state.copyWith(userStates: data, isGettingStats: false)),
          onDone: () => emit(state.copyWith(isGettingStats: false)),
          onError: (_) => emit(state.copyWith(isGettingStats: false)),
        );
  }

  Future<void> getUserMetrics() async {
    await stepRepo
        .getUserMetrics(from: state.from, to: state.to)
        .handle(
          onStart: () => emit(state.copyWith(isGettingUserMetrics: true)),
          onData: (data) => emit(state.copyWith(metrics: data, isGettingUserMetrics: false)),
          onDone: () => emit(state.copyWith(isGettingUserMetrics: false)),
          onError: (_) => emit(state.copyWith(isGettingUserMetrics: false)),
        );
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

  Future<void> deleteUserDailyData() async {
    if (state.period != 0 || state.offset != 0) {
      return;
    }

    final now = DateTime.now();
    final targetDate = DateTime(now.year, now.month, now.day).add(Duration(days: state.offset));
    final dateString =
        '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';

    await stepRepo
        .deleteUserDailyData(date: dateString)
        .handle(
          onStart: () => emit(state.copyWith(isDeletingUserDailyData: true)),
          onData: (success) {
            if (success) {
              emit(
                state.copyWith(
                  metrics: MetricsRequest(foots: 0, distance: 0, kcal: 0, duration: 0),
                  isDeletingUserDailyData: false,
                ),
              );
            } else {
              emit(state.copyWith(isDeletingUserDailyData: false));
            }
          },
          onDone: () => emit(state.copyWith(isDeletingUserDailyData: false)),
          onError: (e) => emit(state.copyWith(isDeletingUserDailyData: false)),
        );
  }

  Future<void> sendDailyData() async {
    await stepRepo
        .sendDailyData(metric: 'Step', value: state.stepCount)
        .handle(
          onStart: () => emit(state),
          onData: (_) => emit(state),
          onDone: () => emit(state),
          onError: (_) => emit(state),
        );
  }

  void changePeriod(int newPeriod) {
    final now = DateTime.now();
    DateTime from;
    DateTime to;

    switch (newPeriod) {
      case 0:
        from = DateTime(now.year, now.month, now.day);
        to = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 1:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        from = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        to = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59);
        break;
      case 2:
        from = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);
        to = DateTime(endOfMonth.year, endOfMonth.month, endOfMonth.day, 23, 59, 59);
        break;
      default:
        return;
    }
    emit(
      state.copyWith(
        period: newPeriod,
        offset: 0,
        from: from.toIso8601String(),
        to: to.toIso8601String(),
      ),
    );
    getSteps();
    getStats(1);
    getUserMetrics();
  }

  void changeOffset(int change) {
    final newOffset = state.offset + change;

    if (change > 0 && newOffset > 0) {
      return;
    }
    if (newOffset == state.offset) return;
    final now = DateTime.now();
    DateTime from;
    DateTime to;

    switch (state.period) {
      case 0: // Daily
        final targetDay = now.add(Duration(days: newOffset));
        from = DateTime(targetDay.year, targetDay.month, targetDay.day);
        to = DateTime(targetDay.year, targetDay.month, targetDay.day, 23, 59, 59);
        break;
      case 1: // Weekly
        final startOfCurrentWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfTargetWeek = startOfCurrentWeek.add(Duration(days: 7 * newOffset));
        from = DateTime(startOfTargetWeek.year, startOfTargetWeek.month, startOfTargetWeek.day);
        final endOfTargetWeek = startOfTargetWeek.add(const Duration(days: 6));
        to = DateTime(endOfTargetWeek.year, endOfTargetWeek.month, endOfTargetWeek.day, 23, 59, 59);
        break;
      case 2: // Monthly
        final targetMonth = DateTime(now.year, now.month + newOffset, 1);
        from = DateTime(targetMonth.year, targetMonth.month, 1);
        final endOfMonth = DateTime(targetMonth.year, targetMonth.month + 1, 0);
        to = DateTime(endOfMonth.year, endOfMonth.month, endOfMonth.day, 23, 59, 59);
        break;
      default:
        return;
    }
    emit(
      state.copyWith(
        offset: newOffset,
        from: from.toIso8601String(),
        to: to.toIso8601String(),
      ),
    );
    getSteps();
    getStats(2);
    getUserMetrics();
  }

  int _buildDailySteps(List<StepsWithMetricsRequest> data) {
    if (data.isEmpty) {
      if (state.offset == 0) {
        return state.stepCount;
      }
      return 0;
    }

    final now = DateTime.now();
    final targetDate = DateTime(now.year, now.month, now.day).add(Duration(days: state.offset));

    final item = data.firstWhere(
      (e) => e.date.year == targetDate.year && e.date.month == targetDate.month && e.date.day == targetDate.day,
      orElse: () => StepsWithMetricsRequest(date: targetDate, value: 0),
    );

    return item.value.toInt();
  }

  List<double> _buildWeeklySteps(List<StepsWithMetricsRequest> data) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final targetWeekStart = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    ).add(Duration(days: 7 * state.offset));

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

  List<double> _buildMonthlySteps(List<StepsWithMetricsRequest> data) {
    final now = DateTime.now();
    final targetMonth = DateTime(now.year, now.month + state.offset);
    final daysInMonth = DateUtils.getDaysInMonth(targetMonth.year, targetMonth.month);

    final List<double> month = List.filled(daysInMonth, 0);

    for (final step in data) {
      if (step.date.year == targetMonth.year && step.date.month == targetMonth.month) {
        final dayIndex = step.date.day - 1;
        if (dayIndex >= 0 && dayIndex < daysInMonth) {
          month[dayIndex] = step.value;
        }
      }
    }

    return month;
  }
}
