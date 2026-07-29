import 'package:calora/domain/model/dailies/steps_stat.dart';
import 'package:calora/domain/model/norms/norms.dart';
import 'package:calora/domain/model/pagination/paginated_response.dart';
import 'package:calora/domain/model/step/metrics_request.dart';
import 'package:calora/domain/model/user/user_stat.dart';

abstract class StepRepo {
  Future<List<StepsWithMetricsRequest>> getSteps(
    int period, {
    int offset = 0,
    bool isSortDate = true,
  });

  Future<MetricsRequest> getUserMetrics({required String from, required String to});

  Future<PaginatedResponse<UserStatRequest>> getStats(
    int period, {
    int offset = 0,
    int skip = 0,
    int take = 20,
  });

  Future<List<NormsRequest>> getNorms();

  Future<void> updateNorm(NormsRequest norm);

  Future<void> deleteNorm(String metric);

  /// POSTs a single daily-metric record. When [date] is null the
  /// server is told it belongs to today; pass an explicit date to
  /// backdate (e.g. historical step backfill).
  Future<void> sendDailyData({
    required String metric,
    required int value,
    DateTime? date,
  });

  Future<void> sendStepDataDateRange({
    required List<StepsWithMetricsRequest> steps,
    DateTime? from,
    DateTime? to,
  });

  Future<void> sendHealthData({required DateTime from, required DateTime to});

  Future<int> getTodayHealthSteps();

  /// Total Steps for a given calendar day (00:00 → 23:59 local time)
  /// read directly from HealthKit / Health Connect. Returns 0 when
  /// Health is unavailable, unpermitted, or has no data for that day.
  Future<int> getHealthStepsForDay(DateTime day);

  /// Rolling 30-day daily step totals from the LOCAL ledger (SQLite,
  /// native FG service history merged in). Returns oldest-first, one
  /// entry per calendar day, with 0 for days that have no record.
  /// Fast + offline — no network round-trip.
  Future<List<StepsWithMetricsRequest>> getLast30DaysLocal();

  Future<bool> isHealthDataAvailable();

  Future<bool> deleteUserDailyData({required String date});

  Map<String, DateTime> getDatePeriods(int period, int offset, {DateTime? now});

  Future<bool> ensureHealthAuthorized();

  Future<bool> hasHealthPermission();

  Future<bool> requestHealthPermission();

  /// Android only (no-op elsewhere): makes sure the separate Health
  /// Connect background-read permission
  /// (`android.permission.health.READ_HEALTH_DATA_IN_BACKGROUND`) is
  /// granted, prompting at most once per install. Without it, newer
  /// Health Connect builds reject the WorkManager isolate's step reads
  /// with a SecurityException and background sync silently dies.
  /// Call from FOREGROUND code paths only — it may show a system dialog.
  Future<void> ensureBackgroundReadAuthorized();

  Future<void> openHealthSettings();
}
