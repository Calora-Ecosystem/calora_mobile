import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class StepsApi {
  final Dio _dio;

  StepsApi(this._dio);

  Future getSteps() async {
    final response = await _dio.get('users/dailies');
    final data = response.data as Map<String, dynamic>;
    log('Steps::::: ${data['total']}');
    return data['total'] as int;
  }

  Future getUserMetrics() async {
    final response = await _dio.get('users/steps/metrics');
    final data = response.data as Map<String, dynamic>;
    log('Metrics:::: ${data['total']}');
    return data['total'] as int;
  }

  Future getStats() async {
    final response = await _dio.get('users/steps/stat');
    final data = response.data as Map<String, dynamic>;
    log('Stats:::: ${data['total']}');
    return data['total'] as int;
  }
}
