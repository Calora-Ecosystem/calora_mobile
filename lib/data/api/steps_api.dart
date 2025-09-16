import 'dart:developer';

import 'package:calora/domain/model/dailies/steps_stat.dart';
import 'package:calora/domain/model/norms/norms.dart';
import 'package:calora/domain/model/step/metrics_data.dart';
import 'package:calora/domain/model/user/user_stat.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart' show lazySingleton;

@lazySingleton
class StepsApi {
  final Dio _dio;

  StepsApi(this._dio);

  Future<List<StepsWithMetrics>> getSteps(int period, {int skip = 0, int take = 7}) async {
    final response = await _dio.get(
      'users/dailies',
      queryParameters: {
        "metrics": "Step",
        "skip": skip,
        "take": take,
        "sortDirection": "Descending",
      },
    );

    final data = response.data;

    if (data is Map<String, dynamic>) {
      final content = data['content'] as List<dynamic>? ?? [];
      return content.map((e) => StepsWithMetrics.fromJson(e)).toList();
    } else {
      return [];
    }
  }

  Future<List<UserStat>> getStats(DateTime from, DateTime to) async {
    final response = await _dio.get(
      "/users/steps/stat",
      queryParameters: {"from": from.toUtc().toIso8601String(), "to": to.toUtc().toIso8601String()},
    );

    final data = response.data;
    final content = data["content"] as List<dynamic>;

    return content.map((json) {
      final user = json["user"];
      return UserStat(
        firstName: user["name"] ?? "",
        lastName: "",
        stepCount: json["sum"] ?? 0,
        talks: json["count"] ?? 0,
        isMe: false,
        isWinner: json["index"] == 1,
      );
    }).toList();
  }

  Future<MetricsData> getUserMetrics() async {
    final response = await _dio.get('users/steps/metrics');
    final data = response.data as Map<String, dynamic>;
    log('Metrics:::: ${data['content']}');
    // TODO: backend response ga qarab to‘liq parse qilish
    return MetricsData(foots: 100, distance: 100, kcal: 50);
  }

  Future<List<Norms>> getNorms() async {
    final response = await _dio.get('/users/norms');
    final List<dynamic> content = response.data['content'];
    return content.map((e) => Norms.fromJson(e)).toList();
  }

  Future<void> updateNorm(Norms norm) async {
    await _dio.post('/users/norms', data: norm.toJson());
  }

  Future<void> deleteNorm(String metric) async {
    await _dio.delete('/users/norms/$metric');
  }
}
