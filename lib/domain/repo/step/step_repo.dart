import 'package:calora/domain/model/dailies/steps_stat.dart';
import 'package:calora/domain/model/norms/norms.dart';
import 'package:calora/domain/model/step/metrics_request.dart';
import 'package:calora/domain/model/user/user_stat.dart';

abstract class StepRepo {
  Future<List<StepsWithMetricsRequest>> getSteps(
    int period, {
    int offset = 0,
    bool isSortDate = true,
  });

  Future<MetricsRequest> getUserMetrics();

  Future<List<UserStatRequest>> getStats(int period, {int offset = 0});

  Future<List<NormsRequest>> getNorms();

  Future<void> updateNorm(NormsRequest norm);

  Future<void> deleteNorm(String metric);

  Future<void> sendDailyData({required String metric, required int value});

  Future<void> sendStepDataDateRange({required List<StepsWithMetricsRequest> steps});
}
