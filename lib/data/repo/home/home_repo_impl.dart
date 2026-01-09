import 'package:calora/data/api/calories_api.dart';
import 'package:calora/data/api/home_api.dart';
import 'package:calora/domain/model/dailies/dailies_request.dart';
import 'package:calora/domain/model/step/metrics_request.dart';
import 'package:calora/domain/model/summary/summary_request.dart';
import 'package:calora/domain/repo/home/home_repo.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: HomeRepo)
class HomeRepoImpl implements HomeRepo {
  final HomeApi _homeApi;
  final CaloriesApi _caloriesApi;

  HomeRepoImpl(this._homeApi, this._caloriesApi);

  @override
  Future<void> postWater(DailiesRequest metric) async {
    await _homeApi.postUserDailies(metric);
  }

  @override
  Future<SummaryRequest> getSummary(DateTime date) async {
    final response = await _caloriesApi.getSummary(date);
    return SummaryRequest.fromJson(response.data['content']);
  }

  @override
  Future<DailiesRequest> getDailiesWater(DateTime date) async {
    return await _homeApi.getDailies(date, 'Water') ??
        DailiesRequest(metric: 'Water', value: 0, date: '');
  }

  @override
  Future<DailiesRequest> getDailiesSteps(DateTime date) async {
    return await _homeApi.getDailies(date, 'Step') ??
        DailiesRequest(metric: 'Step', value: 0, date: 'date');
  }

  @override
  Future<MetricsRequest> getMetrics(DateTime date) async {
    return await _homeApi.getUserMetrics(date) ??
        MetricsRequest(foots: 0, distance: 0, kcal: 0);
  }
}
