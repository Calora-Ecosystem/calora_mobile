import 'package:calora/domain/model/norms/norms.dart';
import 'package:calora/domain/model/questions/questions_request.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class QuestionsApi {
  final Dio _dio;

  QuestionsApi(this._dio);

  Future<Response> sendAnswers(QuestionsRequest request) {
    final data = request.toJson();
    return _dio.post('users/extras', data: data);
  }

  Future<Response> sendTargetWeightAndActivityLevel() {
    return _dio.post('users/extras');
  }

  Future<Response> sendTargetWeight(NormsRequest request) {
    var result = request.toJson();
    return _dio.post('users/norms', data: result);
  }
}
