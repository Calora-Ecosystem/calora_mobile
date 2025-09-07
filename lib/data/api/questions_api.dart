import 'package:calora/domain/model/questions/questions.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class QuestionsApi {
  final Dio _dio;

  QuestionsApi(this._dio);

  Future<Response?> sendAnswers(QuestionsModel answers) async {
    try {
      final data = answers.toJson();
      print('Sending answers: $data');
      final response = await _dio.post('users/extras', data: data);
      print('Response: ${response.data}');

      return response;
    } on DioException catch (e) {
      print('Dio error: ${e.response?.data ?? e.message}');
      return null;
    } catch (e) {
      print('Unexpected error: $e');
      return null;
    }
  }
}
