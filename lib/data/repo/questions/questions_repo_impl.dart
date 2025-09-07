import 'dart:developer';

import 'package:calora/data/api/questions_api.dart';
import 'package:calora/domain/model/questions/questions.dart';
import 'package:calora/domain/repo/questions/questions_repo.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: QuestionsRepo)
class QuestionsRepoImpl extends QuestionsRepo {
  final QuestionsApi _api;

  QuestionsRepoImpl(this._api);

  @override
  Future<void> sendAnswers(QuestionsModel answers) async {
    final response = await _api.sendAnswers(answers);
    log("Answers sent: ${response?.data}");
  }
}
