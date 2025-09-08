import 'package:calora/domain/model/questions/questions_request.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class QuestionsApi {
  final Dio _dio;

  QuestionsApi(this._dio);

  Future<Response> sendAnswers(QuestionsRequest request) async {
    final data = request.toJson();
    return _dio.post('users/extras', data: data);
  }
}
