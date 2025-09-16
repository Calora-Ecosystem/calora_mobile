import 'dart:developer';

import 'package:calora/data/api/steps_api.dart';
import 'package:calora/domain/model/dailies/steps_stat.dart';
import 'package:calora/domain/model/norms/norms.dart';
import 'package:calora/domain/model/step/metrics_data.dart';
import 'package:calora/domain/model/user/user_stat.dart';
import 'package:calora/domain/repo/step/step_repo.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: StepRepo)
class StepRepoImpl extends StepRepo {
  final StepsApi _stepsApi;

  StepRepoImpl(this._stepsApi);

  Future<List<StepsWithMetrics>> getSteps(int period, {int offset = 0}) async {
    final take = period == 0
        ? 1
        : period == 1
        ? 7
        : 30;

    // skip = offset * take
    final skip = offset * take;

    final response = await _stepsApi.getSteps(period, skip: skip, take: take);
    log('steps total:::::::: $response');
    return response;
  }

  Future<MetricsData> getUserMetrics() async {
    final response = await _stepsApi.getUserMetrics();
    log('metrics total:::::::: $response');
    return response;
  }

  Future<List<UserStat>> getStats(int period, {int offset = 0}) async {
    final now = DateTime.now();
    late DateTime from;
    late DateTime to;

    if (period == 0) {
      from = DateTime(now.year, now.month, now.day).add(Duration(days: offset));
      to = from.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
    } else if (period == 1) {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      from = startOfWeek.add(Duration(days: 7 * offset));
      to = from.add(const Duration(days: 7)).subtract(const Duration(seconds: 1));
    } else {
      final startOfMonth = DateTime(now.year, now.month, 1);
      from = DateTime(startOfMonth.year, startOfMonth.month + offset, 1);
      to = DateTime(from.year, from.month + 1, 1).subtract(const Duration(seconds: 1));
    }

    final response = await _stepsApi.getStats(from, to);
    log('stats total:::::::: $response');
    return response;
  }

  @override
  Future<void> updateNorm(Norms norm) => _stepsApi.updateNorm(norm);

  @override
  Future<void> deleteNorm(String metric) => _stepsApi.deleteNorm(metric);

  @override
  Future<List<Norms>> getNorms() async {
    final response = await _stepsApi.getNorms();
    log('norms:::::::: $response');
    return response;
  }
}
