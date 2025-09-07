import 'package:calora/domain/model/questions/questions.dart';

abstract class QuestionsRepo {
  Future<void> sendAnswers(QuestionsModel answers);
}
