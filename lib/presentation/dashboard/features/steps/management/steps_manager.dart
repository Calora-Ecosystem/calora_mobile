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
  Timer? _timer;

  StepsManager(this.stepRepo) : super(StepsState());

  void updateTodaySteps(int steps) {
    emit(state.copyWith(stepCount: steps));
  }

  void start() {
    _timer = Timer.periodic(const Duration(hours: 1), (_) {
      sendDailyData();
    });
    sendDailyData();
  }

  Future<void> getSteps() async {
    await stepRepo
        .getSteps(state.period, offset: state.offset)
        .handle(
          onStart: () => emit(state.copyWith(isLoading: true)),
          onData: (data) {
            List<double> primaryValues = [];

            if (state.period == 1) {
              primaryValues = _buildWeeklySteps(data);
            } else if (state.period == 2) {
              primaryValues = _buildMonthlySteps(data);
            }

            emit(state.copyWith(steps: data, primaryValues: primaryValues, isLoading: false));
          },
          onDone: () => emit(state.copyWith(isLoading: false)),
          onError: (e) {
            log('Error in getSteps: $e');
            emit(state.copyWith(isLoading: false));
          },
        );
  }

  Future<void> getStats(int value) async {
    await stepRepo
        .getStats(state.period, offset: state.offset)
        .handle(
          onStart: () => emit(state.copyWith(isLoading: true)),
          onData: (data) => emit(state.copyWith(userStates: data, isLoading: false)),
          onDone: () => emit(state.copyWith(isLoading: false)),
          onError: (_) => emit(state.copyWith(isLoading: false)),
        );
  }

  Future<void> getUserMetrics() async {
    await stepRepo.getUserMetrics().handle(
      onStart: () => emit(state.copyWith(isLoading: true)),
      onData: (data) => emit(state.copyWith(metrics: data, isLoading: false)),
      onDone: () => emit(state.copyWith(isLoading: false)),
      onError: (_) => emit(state.copyWith(isLoading: false)),
    );
  }

  Future<void> getNorms() async {
    await stepRepo.getNorms().handle(
      onStart: () => emit(state.copyWith(isLoading: true)),
      onData: (data) => emit(state.copyWith(norms: data, isLoading: false)),
      onDone: () => emit(state.copyWith(isLoading: false)),
      onError: (_) => emit(state.copyWith(isLoading: false)),
    );
  }

  Future<void> updateNorm(NormsRequest norm) async {
    await stepRepo
        .updateNorm(norm)
        .handle(
          onStart: () => emit(state.copyWith(isLoading: true)),
          onData: (_) => getNorms(),
          onDone: () => emit(state.copyWith(isLoading: false)),
          onError: (_) => emit(state.copyWith(isLoading: false)),
        );
  }

  Future<void> deleteNorm(String metric) async {
    await stepRepo
        .deleteNorm(metric)
        .handle(
          onStart: () => emit(state.copyWith(isLoading: true)),
          onData: (_) => getNorms(),
          onDone: () => emit(state.copyWith(isLoading: false)),
          onError: (_) => emit(state.copyWith(isLoading: false)),
        );
  }

  Future<void> sendDailyData() async {
    await stepRepo
        .sendDailyData(metric: "Step", value: state.stepCount)
        .handle(
          onStart: () => emit(state),
          onData: (_) => emit(state),
          onDone: () => emit(state),
          onError: (_) => emit(state),
        );
  }

  void changePeriod(int newPeriod) {
    emit(state.copyWith(period: newPeriod, offset: 0));
    getSteps();
    getStats(1);
  }

  void changeOffset(int change) {
    final newOffset = state.offset + change;
    final clampedOffset = newOffset < 0 ? 0 : newOffset;
    if (clampedOffset == state.offset) return;
    emit(state.copyWith(offset: clampedOffset));
    getSteps();
    getStats(2);
  }

  List<double> _buildWeeklySteps(List<StepsWithMetricsRequest> data) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final List<double> week = List.filled(7, 0);

    for (int i = 0; i < 7; i++) {
      final currentDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day + i);

      final item = data.firstWhere(
        (e) =>
            e.date.year == currentDay.year &&
            e.date.month == currentDay.month &&
            e.date.day == currentDay.day,
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
        final dayIndex = step.date.day - 1; // chart list index = kun - 1
        if (dayIndex >= 0 && dayIndex < daysInMonth) {
          month[dayIndex] = step.value;
        }
      }
    }

    return month;
  }
}
