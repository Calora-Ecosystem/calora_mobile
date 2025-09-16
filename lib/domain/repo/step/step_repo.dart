import 'package:calora/domain/model/dailies/steps_stat.dart';
import 'package:calora/domain/model/norms/norms.dart';
import 'package:calora/domain/model/step/metrics_data.dart';
import 'package:calora/domain/model/user/user_stat.dart';

abstract class StepRepo {
  /// Stepsni olish (daily / weekly / monthly)
  Future<List<StepsWithMetrics>> getSteps(int period, {int offset = 0});

  Future<MetricsData> getUserMetrics();

  Future<List<UserStat>> getStats(int period, {int offset = 0});

  Future<List<Norms>> getNorms();

  Future<void> updateNorm(Norms norm);

  Future<void> deleteNorm(String metric);

  Future<void> sendDailyData({required String metric, required int value});
}
