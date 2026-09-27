import 'package:calora/domain/model/report/weekly_report.dart';

abstract class ReportRepo {
  Future<WeeklyReport> getWeekly(DateTime weekStart);
}
