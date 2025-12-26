import 'dart:developer';

import 'package:calora/data/api/steps_api.dart';
import 'package:calora/domain/model/dailies/steps_stat.dart';
import 'package:calora/domain/model/norms/norms.dart';
import 'package:calora/domain/model/step/metrics_request.dart';
import 'package:calora/domain/model/user/user_stat.dart';
import 'package:calora/domain/repo/step/step_repo.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: StepRepo)
class StepRepoImpl extends StepRepo {
  final StepsApi _stepsApi;

  StepRepoImpl(this._stepsApi);

  @override
  Future<List<StepsWithMetricsRequest>> getSteps(int period, {int offset = 0, bool isSortDate = false}) async {
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
  Future<List<UserStatRequest>> getStats(int period, {int offset = 0}) async {
    log('ResultRepoImp: $period, $offset');

    final datePeriod = getDatePeriods(period, offset);

    final response = await _stepsApi.getStats(datePeriod['from']!, datePeriod['to']!);
    return response;
  }

  @override
  Future<void> updateNorm(NormsRequest norm) => _stepsApi.updateNorm(norm);

  @override
  Future<void> sendDailyData({required String metric, required int value}) =>
      _stepsApi.sendDailyData(metric: metric, value: value);

  @override
  Future<void> sendStepDataDateRange({required List<StepsWithMetricsRequest> steps}) =>
      _stepsApi.sendStepDataDateRange(steps: steps);

  @override
  Future<void> deleteNorm(String metric) => _stepsApi.deleteNorm(metric);

  @override
  Future<List<NormsRequest>> getNorms() async {
    final response = await _stepsApi.getNorms();

    return response;
  }

  Map<String, DateTime> getDatePeriods(int period, int offset) {
    final now = DateTime.now();

    late DateTime from;
    late DateTime to;

    if (period == 0) {
      final today = DateTime(now.year, now.month, now.day);
      from = today.add(Duration(days: offset));
      to = from.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
    } else if (period == 1) {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final weekStart = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      from = weekStart.add(Duration(days: 7 * offset));
      to = from.add(const Duration(days: 7)).subtract(const Duration(seconds: 1));
    } else {
      final startOfMonth = DateTime(now.year, now.month);
      from = DateTime(startOfMonth.year, startOfMonth.month + offset);
      to = DateTime(from.year, from.month + 1).subtract(const Duration(seconds: 1));
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
