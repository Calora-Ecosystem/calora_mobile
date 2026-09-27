import 'package:calora/domain/model/report/weekly_report.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';

@lazySingleton
class ReportApi {
  final Dio _dio;

  ReportApi(this._dio);

  /// Report for the Mon–Sun week that contains [weekStart].
  Future<WeeklyReport> getWeekly(DateTime weekStart) async {
    final response = await _dio.get<Map<String, dynamic>>(
      'reports/weekly',
      queryParameters: {
        'weekStart': DateFormat('yyyy-MM-dd').format(weekStart),
      },
    );
    return WeeklyReport.fromJson(
      response.data!['content'] as Map<String, dynamic>,
    );
  }
}
