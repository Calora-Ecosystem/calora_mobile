import 'package:calora/domain/model/dailies/dailies_request.dart';
import 'package:calora/domain/model/step/metrics_request.dart';
import 'package:calora/domain/model/summary/summary_request.dart';

abstract class HomeRepo {
  Future<void> postWater(DailiesRequest metric);

  Future<SummaryRequest> getSummary(DateTime date);

  Future<DailiesRequest> getDailiesWater(DateTime date);

  Future<MetricsRequest> getMetrics(DateTime date);

  Future<DailiesRequest> getDailiesSteps(DateTime date);
}
