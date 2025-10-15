import 'package:calora/domain/model/norms/norms.dart';
import 'package:calora/domain/model/questions/questions_request.dart';

abstract class QuestionsRepo {
  Future<void> sendAnswers(QuestionsRequest answers);
  Future<List<int>> getDailyGoals();
  Future<void> sendTargetWeight(NormsRequest weight);
}
