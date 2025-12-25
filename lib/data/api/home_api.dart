import 'package:calora/domain/model/dailies/dailies_request.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class HomeApi {
  final Dio _dio;

  HomeApi(this._dio);

  Future<void> postUserDailies(DailiesRequest metric) async {
    await _dio.post('/users/dailies', data: metric);
  }
}
