import 'package:calora/data/api/questions_api.dart';
import 'package:calora/data/api/steps_api.dart';
import 'package:calora/domain/model/norms/norms.dart';
import 'package:calora/domain/model/questions/questions_request.dart';
import 'package:calora/domain/repo/questions/questions_repo.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: QuestionsRepo)
class QuestionsRepoImpl extends QuestionsRepo {
  final QuestionsApi _api;
  final StepsApi stepsApi;

  QuestionsRepoImpl(this._api, this.stepsApi);

  @override
  Future<void> sendAnswers(QuestionsRequest answers) async {
    await _api.sendAnswers(answers);
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
