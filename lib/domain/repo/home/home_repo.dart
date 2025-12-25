import 'package:calora/domain/model/dailies/dailies_request.dart';
import 'package:calora/domain/model/summary/summary_request.dart';

abstract class HomeRepo {
  Future<void> postWater(DailiesRequest metric);

  Future<SummaryRequest> getSummary(DateTime date);
}
