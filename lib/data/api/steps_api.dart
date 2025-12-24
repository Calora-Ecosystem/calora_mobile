import 'package:calora/common/base/profile_store.dart';
import 'package:calora/domain/model/dailies/steps_stat.dart';
import 'package:calora/domain/model/norms/norms.dart';
import 'package:calora/domain/model/step/metrics_request.dart';
import 'package:calora/domain/model/user/user_stat.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart' show lazySingleton;

@lazySingleton
class StepsApi {
  final Dio _dio;

  StepsApi(this._dio);

  Future<List<StepsWithMetricsRequest>> getSteps({
    required String metrics,
    int skip = 0,
    int take = 7,
    String sortDirection = 'Descending',
    String sortPropName = '',
    DateTime? from,
    DateTime? to,
  }) async {
    final queryParams = <String, dynamic>{
      'metrics': metrics,
      'skip': skip,
      'take': take,
      'sortDirection': sortDirection,
      'sortPropName': sortPropName,
    };
    if (from != null) {
      queryParams['from'] = from.toIso8601String();
    }
    if (to != null) {
      queryParams['to'] = to.toIso8601String();
    }
    final response = await _dio.get('users/dailies', queryParameters: queryParams);

    final data = response.data;

    if (data is Map<String, dynamic>) {
      final content = data['content'] as List<dynamic>? ?? [];
      return content.map((e) => StepsWithMetricsRequest.fromJson(e)).toList();
    } else {
      return [];
    }
  }

  Future<List<UserStatRequest>> getStats(DateTime from, DateTime to) async {
    final fromUtc = DateTime.utc(from.year, from.month, from.day);
    final toUtc = DateTime.utc(to.year, to.month, to.day, 23, 59, 59);
    final profile = await profileStore.getProfile();
    final currentEmail = profile.email?.toLowerCase() ?? '';
    final response = await _dio.get(
      '/users/steps/stat',
      queryParameters: {'from': fromUtc.toIso8601String(), 'to': toUtc.toIso8601String()},
    );
    final data = response.data;
    final content = data['content'] as List<dynamic>;
    return content.map((json) {
      final user = json['user'];
      final userEmail = (user['email'] ?? '').toString().toLowerCase();
      return UserStatRequest(
        firstName: user['name'] ?? '',
        lastName: '',
        stepCount: json['sum'] ?? 0,
        talks: json['count'] ?? 0,
        isMe: userEmail == currentEmail,
        isWinner: json['index'] == 1,
      );
    }).toList();
  }

  Future<MetricsRequest> getUserMetrics() async {
    final response = await _dio.get('users/steps/metrics');
    final data = response.data as Map<String, dynamic>;
    return MetricsRequest(foots: 100, distance: 100, kcal: 50);
  }

  Future<List<NormsRequest>> getNorms() async {
    final response = await _dio.get('/users/norms');
    final List<dynamic> content = response.data['content'];
    return content.map((e) => NormsRequest.fromJson(e)).toList();
  }

  Future<void> updateNorm(NormsRequest norm) async {
    await _dio.post('/users/norms', data: norm.toJson());
  }

  Future<void> deleteNorm(String metric) async {
    await _dio.delete('/users/norms/$metric');
  }

  Future<void> sendDailyData({required String metric, required int value}) async {
    final body = {'metric': metric, 'value': value, 'date': DateTime.now().toUtc().toIso8601String()};
    await _dio.post('/users/dailies', data: body);
  }

  Future<void> sendStepDataDateRange({List<StepsWithMetricsRequest> steps = const []}) async {
    final payload = steps.map((element) => element.toJson()).toList();
    await _dio.post('/users/dailies/batch', data: payload);
  }
}
