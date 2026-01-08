import 'package:calora/data/api/questions_api.dart';
import 'package:calora/data/api/steps_api.dart';
import 'package:calora/data/store/common/common_store.dart';
import 'package:calora/domain/model/norms/norms.dart';
import 'package:calora/domain/model/questions/questions_request.dart';
import 'package:calora/domain/repo/questions/questions_repo.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: QuestionsRepo)
class QuestionsRepoImpl extends QuestionsRepo {
  final QuestionsApi _api;
  final StepsApi stepsApi;
  final CommonStore _commonStore;
  QuestionsRepoImpl(this._api, this.stepsApi, this._commonStore);

  @override
  Future<void> sendAnswers(QuestionsRequest answers) async {
    final response = await _api.sendAnswers(answers);
    if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
      await _commonStore.isQuestionaryFinished.set(true);
    }
  }

  Future<void> sendTargetWeight(NormsRequest weight) async {
    await _api.sendTargetWeight(weight);
  }

  @override
  Future<List<double>> getDailyGoals() async {
    final List<NormsRequest> list = await stepsApi.getNorms();
    final orderedMetrics = ['Kcal', 'Step', 'Water'];
    final List<double> goals = orderedMetrics
        .map(
          (metric) => list
              .firstWhere(
                (e) => e.metric == metric,
                orElse: () => NormsRequest(metric: metric, value: 0),
              )
              .value,
        )
        .toList();

    return goals;
  }
}
