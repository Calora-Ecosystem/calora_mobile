import 'package:calora/data/api/questions_api.dart';
import 'package:calora/domain/model/norms/norms.dart';
import 'package:calora/domain/model/questions/questions_request.dart';
import 'package:calora/domain/repo/questions/questions_repo.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: QuestionsRepo)
class QuestionsRepoImpl extends QuestionsRepo {
  final QuestionsApi _api;

  QuestionsRepoImpl(this._api);

  @override
  Future<void> sendAnswers(QuestionsRequest answers) async {
    await _api.sendAnswers(answers);
  }

  Future<void> sendTargetWeight(NormsRequest weight) async {
    await _api.sendTargetWeight(weight);
  }

  @override
  Future<List<int>> getDailyGoals() {
    return Future.value(goals);
  }

  List<int> goals = [2000, 600, 2200];
}
