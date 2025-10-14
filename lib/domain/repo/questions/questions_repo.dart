import 'package:calora/domain/model/questions/questions_request.dart';

abstract class QuestionsRepo {
  Future<void> sendAnswers(QuestionsRequest answers);
  Future<List<int>> getDailyGoals();
}
