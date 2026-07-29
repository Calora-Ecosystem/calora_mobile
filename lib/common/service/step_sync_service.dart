import 'dart:developer';
import 'dart:io';

import 'package:calora/common/base/step_ledger_db.dart';
import 'package:calora/domain/model/dailies/steps_stat.dart';
import 'package:calora/domain/repo/step/step_repo.dart';

/// The single write-pipeline between local step data and the backend.
///
/// Architecture rule this class enforces: every data source (native FG
/// service counters, Health Connect / HealthKit aggregates, in-process
/// pedometer) merges into the SQLite ledger FIRST via max-semantics, and
/// the backend only ever receives what the ledger says — through
/// [syncPendingToBackend], with `step_days.synced` as the one and only
/// high-water tracker.
///
/// Why one pipeline matters: before this class, the foreground timer,
/// the startup health backfill, and the background worker each POSTed
/// independently with their own tracking. Two of those paths could
/// disagree on a day's value, and on a last-write-wins backend the later
/// (lower) write silently downgraded the weekly/monthly charts. With a
/// single pipeline the value POSTed for a day is monotonically
/// non-decreasing for the life of that day, so the backend can only ever
/// converge upward toward the true total.
///
/// Both isolates construct their own instance (it's stateless apart from
/// a per-isolate re-entrancy guard); cross-isolate consistency comes
/// from the ledger's atomic SQL, not from shared memory. If both
/// isolates happen to sync the same pending day simultaneously, they
/// POST the same value — idempotent on an upsert-by-date backend.
class StepSyncService {
  StepSyncService(this._stepRepo);

  final StepRepo _stepRepo;
  final StepLedgerDb _db = StepLedgerDb.instance;

  /// Hard cap on days per sync cycle — bounds the worst-case batch after
  /// very long offline stretches (a month + margin covers the ledger's
  /// 30-day rolling window).
  static const int maxDaysPerSync = 31;

  /// Per-isolate re-entrancy guard: the foreground 1-min timer, launch
  /// backfill, and health backfill may overlap; running one cycle at a
  /// time keeps the POST order deterministic.
  bool _syncing = false;

  // ── Health history → ledger ─────────────────────────────────────────

  /// Pulls per-day Health totals for the past [days] (yesterday and
  /// back — today is owned by the live paths) into the ledger via
  /// max-merge. Never POSTs anything itself; follow with
  /// [syncPendingToBackend].
  ///
  /// With [oncePerDay] the read is skipped if it already completed today
  /// (marker in the ledger meta table). The 4-min background chain uses
  /// this so Health history is polled at most once per calendar day —
  /// the chain's steady-state cost stays a couple of cheap queries.
  Future<void> hydrateHealthHistory(
      {required int days, bool oncePerDay = false}) async {
    try {
      final todayKey = StepLedgerDb.dayKey(DateTime.now());
      if (oncePerDay &&
          await _db.getHealthHistoryHydratedDay() == todayKey) {
        return;
      }

      if (!await _stepRepo.isHealthDataAvailable()) return;
      // Android: read only with permission already granted (a background
      // isolate must never trigger the permission UI). iOS HealthKit
      // hides read status — getHealthStepsForDay probes directly there
      // and coalesces a denied read to 0.
      if (!Platform.isIOS && !await _stepRepo.hasHealthPermission()) return;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      var hydrated = 0;
      for (var i = 1; i <= days; i++) {
        final day = today.subtract(Duration(days: i));
        try {
          final steps = await _stepRepo.getHealthStepsForDay(day);
          if (steps > 0) {
            await _db.ensureDayAtLeast(StepLedgerDb.dayKey(day), steps);
            hydrated++;
          }
        } catch (e) {
          log('Health hydration failed for $day: $e',
              name: 'StepSyncService');
        }
      }

      // Marker written only after a completed pass, so an interrupted
      // hydration re-runs on the next cycle instead of losing the day.
      await _db.setHealthHistoryHydratedDay(todayKey);
      log('Health history hydrated: $hydrated/$days day(s)',
          name: 'StepSyncService');
    } catch (e) {
      log('hydrateHealthHistory failed: $e', name: 'StepSyncService');
    }
  }

  // ── Ledger → backend ────────────────────────────────────────────────

  /// POSTs every pending day (`total > synced`) to the backend and
  /// advances the high-water mark per confirmed success.
  ///
  /// Shape of a cycle:
  ///  • Today → the single-day endpoint (`sendDailyData`), same endpoint
  ///    the 1-min foreground sync has always used.
  ///  • Past days → ONE batch POST (`sendStepDataDateRange`); if the
  ///    batch endpoint rejects, a sequential per-day fallback with
  ///    explicit dates. Sequential on purpose — no parallel fan-out, so
  ///    a 30-day backfill is 1 request in the common case and at worst a
  ///    quiet drip of small ones, never a thundering herd.
  ///
  /// Failure handling: a failed day simply stays pending (`synced` is
  /// only advanced on success) and is retried on the next cycle — the
  /// 1-min foreground timer or the 4-min background chain, whichever
  /// comes first. No state is lost by a mid-cycle crash for the same
  /// reason.
  Future<void> syncPendingToBackend() async {
    if (_syncing) return;
    _syncing = true;
    try {
      final pending =
          await _db.getPendingDaysWithTotals(limit: maxDaysPerSync);
      if (pending.isEmpty) return;

      final todayKey = StepLedgerDb.dayKey(DateTime.now());

      for (final p in pending.where((p) => p.day == todayKey)) {
        try {
          await _stepRepo.sendDailyData(metric: 'Step', value: p.total);
          await _db.setSynced(p.day, p.total);
        } catch (e) {
          log('Today sync failed (retries next cycle): $e',
              name: 'StepSyncService');
        }
      }

      final past = pending.where((p) => p.day != todayKey).toList();
      if (past.isEmpty) return;

      final payload = [
        for (final p in past)
          StepsWithMetricsRequest(
            date: DateTime.parse(p.day),
            value: p.total.toDouble(),
          ),
      ];

      try {
        await _stepRepo.sendStepDataDateRange(steps: payload);
        for (final p in past) {
          await _db.setSynced(p.day, p.total);
        }
        log('Backfill: ${past.length} past day(s) POSTed via batch '
            '(${past.first.day} → ${past.last.day})',
            name: 'StepSyncService');
        return;
      } catch (e) {
        log('Backfill batch failed ($e) — per-day fallback',
            name: 'StepSyncService');
      }

      var sent = 0;
      for (final p in past) {
        try {
          await _stepRepo.sendDailyData(
            metric: 'Step',
            value: p.total,
            date: DateTime.parse(p.day),
          );
          await _db.setSynced(p.day, p.total);
          sent++;
        } catch (e) {
          log('Backfill POST for ${p.day} failed: $e',
              name: 'StepSyncService');
        }
      }
      log('Backfill: $sent/${past.length} past day(s) POSTed via fallback',
          name: 'StepSyncService');
    } finally {
      _syncing = false;
    }
  }
}
