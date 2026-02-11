import 'package:calora/domain/model/dailies/dailies_request.dart';
import 'package:calora/domain/model/step/metrics_request.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class HomeApi {
  final Dio _dio;

  HomeApi(this._dio);

  Future<void> postUserDailies(DailiesRequest metric) async {
    await _dio.post('/users/dailies', data: metric);
  }

  Future<DailiesRequest?> getDailies(DateTime date, String metric) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);

    final response = await _dio.get(
      '/users/dailies',
      queryParameters: {
        'from': formattedDate,
        'to': formattedDate,
        'metrics': metric,
      },
    );
    final List list = response.data['content'];
    if (list.isEmpty) return null;
    return DailiesRequest.fromJson(list.first);
  }

  Future<MetricsRequest?> getUserMetrics(DateTime date) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);

    final response = await _dio.get(
      'users/steps/metrics',
      queryParameters: {'from': formattedDate, 'to': formattedDate},
    );

    final data = response.data['content'];

    if (data == null) return null;

    return MetricsRequest.fromJson(data);
  }

  Future<String> getLatestVersionKey() async {
    final res = await _dio.get('/versions/latest');
    return res.data['content']['key']?.toString() ?? '';
  }

  Future<bool> isVersionActive(String version) async {
    final res = await _dio.get('/versions/$version');
    return (res.data['content']['isActive'] == true);
  }
}
