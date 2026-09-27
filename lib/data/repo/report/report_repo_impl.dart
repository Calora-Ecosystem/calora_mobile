import 'package:calora/common/base/step_ledger_db.dart';
import 'package:calora/data/api/report_api.dart';
import 'package:calora/domain/model/report/weekly_report.dart';
import 'package:calora/domain/repo/report/report_repo.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: ReportRepo)
class ReportRepoImpl implements ReportRepo {
  final ReportApi _api;

  ReportRepoImpl(this._api);

  @override
  Future<WeeklyReport> getWeekly(DateTime weekStart) async {
    final report = await _api.getWeekly(weekStart);
    return report.mergeLocalSteps(await _localSteps(report));
  }

  /// Step totals the device counted for the report's days — steps that
  /// haven't reached the server yet would otherwise be missing.
  Future<Map<DateTime, int>> _localSteps(WeeklyReport report) async {
    final result = <DateTime, int>{};
    try {
      for (final day in report.days) {
        final date = DateTime(day.date.year, day.date.month, day.date.day);
        final total = await StepLedgerDb.instance.totalFor(
          StepLedgerDb.dayKey(date),
        );
        if (total > 0) result[date] = total;
      }
    } catch (_) {
      // Ledger unavailable (e.g. tests) — the server numbers stand.
    }
    return result;
  }
}
