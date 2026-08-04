import 'package:calora/common/constants/request_extras.dart';
import 'package:calora/domain/model/norms/norms.dart';
import 'package:calora/domain/model/questions/questions_request.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class QuestionsApi {
  final Dio _dio;

  QuestionsApi(this._dio);

  // The questionary screen surfaces its own error SnackBar, so these requests
  // opt out of the interceptor's app-wide error display.
  static final _selfHandledErrors =
      Options(extra: {kSkipGlobalErrorDisplay: true});

  Future<Response> sendAnswers(QuestionsRequest request) {
    final data = request.toJson();
    return _dio.post('users/extras', data: data, options: _selfHandledErrors);
  }

  Future<Response> sendTargetWeightAndActivityLevel() {
    return _dio.post('users/extras');
  }

  Future<Response> sendTargetWeight(NormsRequest request) {
    final result = request.toJson();
    return _dio.post('users/norms', data: result, options: _selfHandledErrors);
  }

  Future<void> send30DailyNotification() async {}
}
