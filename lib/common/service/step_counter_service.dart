import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:calora/common/base/step_ledger_store.dart';
import 'package:calora/common/service/foreground_service.dart';
import 'package:calora/common/service/installed_health_apps_service.dart';
import 'package:calora/common/service/pedometer_service.dart';
import 'package:calora/domain/repo/step/step_repo.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

/// Which local source the service is reading from.
enum StepSource { health, pedometer, none }

/// Cross-cutting events the service raises so the UI layer can react
/// (rationale dialogs, sync-troubleshooting prompts, etc.). The service
/// itself never touches `BuildContext`.
sealed class StepCounterEvent {
  const StepCounterEvent();
}

/// Emitted when Health permission is granted but the central health
/// repository keeps returning ~0 steps after the grace period AND a
/// known third-party tracker is installed (Samsung Health, Mi Fitness,
/// etc.). The UI should surface a dialog telling the user to enable
/// that app's sync to Health Connect / HealthKit.
class HealthDataNotSyncing extends StepCounterEvent {
  /// One of `samsung_health`, `mi_fitness`, `unknown`, or `ios`.
  final String detectedApp;
  const HealthDataNotSyncing(this.detectedApp);
}

/// Single source of truth for today's step total.
///
/// Architecture
/// ────────────
/// 1. **Primary** — central OS health repository (Health Connect on
///    Android, HealthKit on iOS). Polled every 5 s while in this mode.
/// 2. **Fallback** — device pedometer sensor. Used when Health is
///    unavailable, unpermitted, or the user explicitly forces it.
/// 3. **Local-only** — the daily total is computed entirely on-device.
///    Backend values are never read as a source of truth; the backend
///    only receives writes (see "Backend sync" below).
/// 4. **Single output** — `stream` (broadcast, replays the latest value)
///    feeds both the UI and the Android foreground notification.
///
/// Backend sync
/// ────────────
/// Every [_backendSyncInterval] (1 min) the service POSTs the current
/// step total to `stepRepo.sendDailyData(metric: 'Step', …)` so the
/// server's daily history stays current for charts / cross-device read.
/// The POST fires on every tick regardless of whether the count
/// changed — the requirement is a heartbeat, not a diff. The only
/// skip is when [currentSteps] is 0, so a momentary zero never
/// overwrites a real value on the server. A failed POST is silently
/// swallowed; the next tick (60 s later) just tries again with the
/// latest total.
///
/// Stuck-Health detection
/// ──────────────────────
/// On many Android devices Health Connect is installed and permitted
/// but a third-party tracker (Samsung Health, Mi Fitness…) hasn't been
/// configured to sync into it, so we'd otherwise show a stale "0
/// steps". After [_stuckHealthGracePeriod] the service samples Health
/// again; if it's still under [_stuckHealthThreshold] and we can
/// detect such an app, the service raises [HealthDataNotSyncing] on
/// [events]. Fires at most once per process.
///
/// The Android `BackgroundStepsWorker` runs in a separate isolate and
/// cannot read this stream. It writes directly to the same
/// `StepLedgerStore` (every 15 min via Workmanager) and also POSTs to
/// the same backend endpoint — overlapping writes are safe since the
/// endpoint is last-write-wins.
@lazySingleton
class StepCounterService {
  final StepRepo _stepRepo;
  final PedometerService _pedometer;
  final StepLedgerStore _ledger;

  StepCounterService(this._stepRepo, this._pedometer)
      : _ledger = StepLedgerStore();

  // ── Public surface ──────────────────────────────────────────────────

  /// Broadcast stream of today's total steps. Latest value is replayed
  /// to new subscribers (`BehaviorSubject`).
  Stream<int> get stream => _subject.stream;

  /// Synchronous read of the latest emitted value.
  int get currentSteps => _subject.valueOrNull ?? 0;

  /// Which local source is currently active.
  StepSource get source => _source;

  /// One-off events surfaced to the UI layer (see [StepCounterEvent]).
  Stream<StepCounterEvent> get events => _events.stream;

  // ── Internals ───────────────────────────────────────────────────────

  final _subject = BehaviorSubject<int>.seeded(0);
  final _events = StreamController<StepCounterEvent>.broadcast();

  StreamSubscription<int>? _sensorSub;
  Timer? _pollTimer;
  Timer? _stuckHealthTimer;
  Timer? _backendSyncTimer;

  StepSource _source = StepSource.none;

  /// Set to `true` after we've raised [HealthDataNotSyncing] this
  /// process so we don't nag the user repeatedly.
  bool _stuckHealthRaised = false;

  bool _initialized = false;
  Future<void>? _initFuture;

  static const Duration _pollInterval = Duration(seconds: 5);
  static const Duration _stuckHealthGracePeriod = Duration(seconds: 15);
  static const Duration _backendSyncInterval = Duration(minutes: 1);

  /// How many days of Health history to push to the backend on startup.
  /// Sized to cover the monthly chart's full window so a user who
  /// hasn't opened the app for a few weeks doesn't see empty trailing
  /// bars while the data is still in HealthKit / Health Connect.
  static const int _backfillDays = 30;

  /// If Health is reporting fewer steps than this after the grace
  /// period we treat the source as "stuck" and surface the dialog
  /// (assuming a third-party tracker is installed).
  static const int _stuckHealthThreshold = 50;

  // ── Lifecycle ───────────────────────────────────────────────────────

  Future<void> start() => _initFuture ??= _startInternal();

  Future<void> _startInternal() async {
    if (_initialized) return;
    _initialized = true;

    // INSTANT — paint the cached value from the ledger so the UI never
    // flashes 0 while we wait on Health / sensor.
    final cached = _ledger.totalFor(_ledger.dayKey(DateTime.now()));
    if (cached > 0) _emit(cached);

    if (await _useHealthIfAvailable()) {
      _source = StepSource.health;
      _scheduleStuckHealthCheck();
      // Backfill: server only has today's writes from the 1-min sync.
      // On Health-mode startup, push the last _backfillDays of daily
      // totals so the history charts stay accurate after a new
      // install, a re-login, or a stretch where the app wasn't open.
      unawaited(_backfillHistoricalDays());
    } else {
      await _useSensor();
    }

    _startBackendSync();
  }

  Future<void> stop() async {
    await _sensorSub?.cancel();
    _sensorSub = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _stuckHealthTimer?.cancel();
    _stuckHealthTimer = null;
    _backendSyncTimer?.cancel();
    _backendSyncTimer = null;
    _initialized = false;
    _initFuture = null;
  }

  /// Re-attempt the Health path. Call this after the user grants
  /// permission via the rationale dialog, or on app-resume on iOS
  /// (where the user might have fixed permission in Settings without
  /// us knowing), so we can switch from pedometer → health without an
  /// app restart.
  Future<void> retryHealth() async {
    if (_source == StepSource.health) return;
    try {
      if (!await _stepRepo.isHealthDataAvailable()) return;

      // Same iOS caveat as `_useHealthIfAvailable`: hasHealthPermission
      // is unreliable on iOS, so we probe the data store directly.
      if (!Platform.isIOS) {
        if (!await _stepRepo.hasHealthPermission()) return;
      }

      final initial = await _stepRepo.getTodayHealthSteps();
      if (Platform.isIOS && initial <= 0) {
        // Still no data — stay on pedometer.
        return;
      }

      await _sensorSub?.cancel();
      _sensorSub = null;
      _source = StepSource.health;
      _stuckHealthRaised = false;

      if (initial > 0) {
        final todayKey = _ledger.dayKey(DateTime.now());
        await _ledger.ensureDayAtLeast(todayKey, initial);
        _emit(initial);
      }

      _startHealthPolling();
      _scheduleStuckHealthCheck();
    } catch (e, s) {
      log('retryHealth failed: $e',
          name: 'StepCounterService', stackTrace: s);
    }
  }

  /// Force the pedometer fallback path. Used when the stuck-Health
  /// dialog's "Use pedometer instead" option is chosen.
  Future<void> forcePedometer() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    _stuckHealthTimer?.cancel();
    _stuckHealthTimer = null;
    await _useSensor();
  }

  Future<void> dispose() async {
    await stop();
    await _subject.close();
    await _events.close();
  }

  // ── Health primary path ─────────────────────────────────────────────

  Future<bool> _useHealthIfAvailable() async {
    try {
      if (!await _stepRepo.isHealthDataAvailable()) return false;

      // iOS HealthKit never reports READ-permission status back to the
      // app (Apple privacy model) — `hasHealthPermission()` returns
      // `false` even after the user has granted access. So we gate on
      // it only on Android (Health Connect), and treat iOS as
      // "optimistically permitted": probe the store directly and let
      // the actual data response tell us whether we can read.
      if (!Platform.isIOS) {
        if (!await _stepRepo.hasHealthPermission()) return false;
      }

      final initial = await _stepRepo.getTodayHealthSteps();
      if (Platform.isIOS && initial <= 0) {
        // iOS got zero on the first probe. That can mean either
        // permission was actually denied, or the user just hasn't
        // walked yet today. Pedometer covers both cases — it counts
        // any new steps from now. We retry Health on next app resume
        // (see `DashboardManager.didChangeAppLifecycleState`) so a
        // mid-day permission fix in Settings will promote back.
        log('iOS Health probe returned 0 — using pedometer',
            name: 'StepCounterService');
        return false;
      }

      if (initial > 0) {
        final todayKey = _ledger.dayKey(DateTime.now());
        await _ledger.ensureDayAtLeast(todayKey, initial);
        _emit(initial);
      }

      _startHealthPolling();
      return true;
    } catch (e, s) {
      log('Health activation failed: $e',
          name: 'StepCounterService', stackTrace: s);
      return false;
    }
  }

  Future<void> _refreshFromHealth() async {
    final fresh = await _stepRepo.getTodayHealthSteps();
    if (fresh <= 0) return;

    final todayKey = _ledger.dayKey(DateTime.now());
    await _ledger.ensureDayAtLeast(todayKey, fresh);
    _emit(fresh);
  }

  void _startHealthPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      try {
        await _refreshFromHealth();
      } catch (e) {
        log('Health poll error: $e', name: 'StepCounterService');
      }
    });
  }

  // ── Stuck-Health detection ──────────────────────────────────────────

  void _scheduleStuckHealthCheck() {
    if (_stuckHealthRaised) return;
    _stuckHealthTimer?.cancel();
    _stuckHealthTimer = Timer(_stuckHealthGracePeriod, _checkStuckHealth);
  }

  Future<void> _checkStuckHealth() async {
    if (_stuckHealthRaised) return;
    if (_source != StepSource.health) return;
    if (currentSteps >= _stuckHealthThreshold) return;

    try {
      // Force a fresh read in case the timer fired between polls.
      final latest = await _stepRepo.getTodayHealthSteps();
      if (latest >= _stuckHealthThreshold) return;

      final app = await InstalledHealthAppsService.detectPrimaryHealthApp();
      // Don't prompt when we can't even guess which app to point at —
      // dialog becomes generic noise. iOS handled separately by the UI.
      if (app == null || app == 'unknown') return;

      _stuckHealthRaised = true;
      if (!_events.isClosed) _events.add(HealthDataNotSyncing(app));
    } catch (e) {
      log('Stuck-health check failed: $e', name: 'StepCounterService');
    }
  }

  // ── Pedometer fallback path ─────────────────────────────────────────

  Future<void> _useSensor() async {
    await _pedometer.initialize();
    if (!_pedometer.isInitialized) {
      _source = StepSource.none;
      _emit(_ledger.totalFor(_ledger.dayKey(DateTime.now())));
      return;
    }
    _source = StepSource.pedometer;
    _listenToSensor();
  }

  void _listenToSensor() {
    _sensorSub?.cancel();
    _sensorSub = _pedometer.stepCountStream.listen(
      _onSensorTick,
      onError: (e) =>
          log('Pedometer error: $e', name: 'StepCounterService'),
    );
  }

  Future<void> _onSensorTick(int sensorTotal) async {
    final now = DateTime.now();
    final todayKey = _ledger.dayKey(now);
    final lastSavedDate = _ledger.getLastSensorDate();
    final lastSensorTotal = _ledger.getLastSensorTotal();

    // Day rollover — close out yesterday, reset baseline, start fresh.
    if (lastSavedDate != todayKey) {
      if (lastSensorTotal >= 0 && sensorTotal > lastSensorTotal) {
        await _ledger.addSteps(lastSavedDate, sensorTotal - lastSensorTotal);
      }
      await _ledger.setLastSensorDate(todayKey);
      await _ledger.setLastSensorTotal(sensorTotal);
      _emit(0);
      return;
    }

    // First read after install / reset — establish baseline only.
    if (lastSensorTotal < 0) {
      await _ledger.setLastSensorTotal(sensorTotal);
      return;
    }

    // Reboot — sensor counter restarted from 0; treat the new value as
    // the delta and let it accumulate on top of the ledger total.
    final delta = sensorTotal < lastSensorTotal
        ? sensorTotal
        : sensorTotal - lastSensorTotal;
    await _ledger.setLastSensorTotal(sensorTotal);
    if (delta <= 0) return;

    await _ledger.addSteps(todayKey, delta);
    _emit(_ledger.totalFor(todayKey));
  }

  // ── Backend backfill (one-shot on startup) ──────────────────────────

  /// Pushes the last [_backfillDays] of Health daily totals to the
  /// backend. Tries the batch endpoint first (`POST
  /// /users/dailies/batch`) and falls back to per-day single POSTs
  /// (`POST /users/dailies`) if the batch call throws — that way the
  /// historical sync still completes even if the server hasn't
  /// shipped the batch endpoint yet.
  ///
  /// Runs once per service startup in the background — `unawaited`
  /// from the caller, so it never blocks the UI paint. Re-running on
  /// every cold start is intentional: the endpoints are upsert-by-date
  /// on the server, so re-POSTing yesterday with its finalized count
  /// (after midnight passes and Health settles) corrects any value
  /// the 1-min sync wrote earlier while the day was still in progress.
  Future<void> _backfillHistoricalDays() async {
    final now = DateTime.now();
    final from = now.subtract(const Duration(days: _backfillDays));

    log('Backfill starting ($_backfillDays days)…',
        name: 'StepCounterService');

    // 1) Build the list of non-zero day totals from Health.
    final totals = <DateTime, int>{};
    for (var i = 0; i <= _backfillDays; i++) {
      final day = DateTime(from.year, from.month, from.day)
          .add(Duration(days: i));
      try {
        final steps = await _stepRepo.getHealthStepsForDay(day);
        if (steps > 0) totals[day] = steps;
      } catch (e) {
        log('Backfill: Health read failed for $day: $e',
            name: 'StepCounterService');
      }
    }

    if (totals.isEmpty) {
      log('Backfill: nothing to send (all days returned 0).',
          name: 'StepCounterService');
      return;
    }
    log('Backfill: ${totals.length} non-zero day(s) to POST: '
        '${totals.entries.map((e) => "${e.key.toIso8601String().substring(0, 10)}=${e.value}").join(", ")}',
        name: 'StepCounterService');

    // 2) Try the batch endpoint.
    try {
      await _stepRepo.sendHealthData(from: from, to: now);
      log('Backfill: batch POST succeeded.', name: 'StepCounterService');
      return;
    } catch (e) {
      log('Backfill: batch POST failed ($e) — falling back to per-day '
          'single POSTs.',
          name: 'StepCounterService');
    }

    // 3) Fallback — per-day POSTs via the same endpoint the 1-min
    //    sync already uses, with explicit `date` so we don't all
    //    collapse onto today. Sequential so we don't spam the auth
    //    interceptor in parallel and trip rate-limits.
    int sent = 0;
    for (final entry in totals.entries) {
      try {
        await _stepRepo.sendDailyData(
          metric: 'Step',
          value: entry.value,
          date: entry.key,
        );
        sent++;
      } catch (e) {
        log('Backfill: single POST for ${entry.key} failed: $e',
            name: 'StepCounterService');
      }
    }
    log('Backfill: $sent / ${totals.length} day(s) POSTed via fallback.',
        name: 'StepCounterService');
  }

  // ── Backend sync (1 min) ────────────────────────────────────────────

  void _startBackendSync() {
    _backendSyncTimer?.cancel();
    _backendSyncTimer = Timer.periodic(
      _backendSyncInterval,
      (_) => unawaited(_pushToBackend()),
    );
  }

  /// POSTs today's running total to `stepRepo.sendDailyData` on every
  /// tick. We deliberately do **not** dedupe against the previous
  /// value — the requirement is "every minute, send the current
  /// total", so the server gets a fresh write each tick regardless of
  /// whether the count moved. Skipped only when we have nothing
  /// meaningful to send (0 steps), to avoid overwriting a real
  /// value in the day's record with a momentary zero.
  Future<void> _pushToBackend() async {
    final steps = currentSteps;
    if (steps <= 0) return;

    try {
      await _stepRepo.sendDailyData(metric: 'Step', value: steps);
    } catch (e) {
      log('Backend sync failed (will retry in 1 min): $e',
          name: 'StepCounterService');
    }
  }

  // ── Emission ────────────────────────────────────────────────────────

  void _emit(int total) {
    if (total < 0) total = 0;
    if (_subject.valueOrNull == total) return;
    _subject.add(total);

    // Mirror to the Android foreground notification — single writer, so
    // the UI and the notification can never disagree.
    if (Platform.isAndroid && StepsForegroundService.instance.isRunning) {
      unawaited(StepsForegroundService.instance.syncSteps(total));
    }
  }
}
