import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:calora/common/base/step_ledger_store.dart';
import 'package:calora/common/service/foreground_service.dart';
import 'package:calora/common/service/pedometer_service.dart';
import 'package:calora/domain/repo/step/step_repo.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

/// Which local source the service is reading from.
enum StepSource { health, pedometer, none }

/// Centralized step-count source of truth.
///
/// Algorithm (in order):
///   1. Try Health (HealthKit / Health Connect). If permission granted and
///      it returns a value, that is the local steps.
///   2. Otherwise fall back to the device pedometer sensor.
///   3. Fetch today's steps from backend.
///        - if local is 0 OR local < backend → use backend as the BASE.
///        - new physical steps after that are added on top of the base.
///   4. Emit the running total on [stream] / [valueNotifier]. Both the UI
///      and the Android foreground notification listen to the same stream.
///
/// The service is process-local. The Android background isolate spawned
/// by `BackgroundStepsWorker` cannot read this stream — it writes directly
/// to the same `StepLedgerStore`, so the next foreground pump picks up
/// whatever it accumulated.
@lazySingleton
class StepCounterService {
  final StepRepo _stepRepo;
  final PedometerService _pedometer;
  final StepLedgerStore _ledger;

  StepCounterService(this._stepRepo, this._pedometer)
      : _ledger = StepLedgerStore();

  // ── Public surface ──────────────────────────────────────────────────

  /// Broadcast stream of today's total steps.
  /// Latest value is replayed to new subscribers (`BehaviorSubject`).
  Stream<int> get stream => _subject.stream;

  /// Synchronous read of the latest emitted value.
  int get currentSteps => _subject.valueOrNull ?? 0;

  /// Which local source is currently active (for debugging / UI).
  StepSource get source => _source;

  // ── Internals ───────────────────────────────────────────────────────

  final _subject = BehaviorSubject<int>.seeded(0);

  StreamSubscription<int>? _sensorSub;
  Timer? _pollTimer;

  StepSource _source = StepSource.none;

  /// Persistent base — anchors the running total. New pedometer / health
  /// deltas are added on top of this.
  int _base = 0;

  /// Last raw pedometer counter we've seen, used to compute deltas across
  /// device reboots and day rollovers. Persisted in the ledger.
  bool _initialized = false;
  Future<void>? _initFuture;

  static const Duration _pollInterval = Duration(seconds: 5);

  // ── Lifecycle ───────────────────────────────────────────────────────

  Future<void> start() {
    return _initFuture ??= _startInternal();
  }

  Future<void> _startInternal() async {
    if (_initialized) return;
    _initialized = true;

    // 1. INSTANT: paint the cached value from the ledger so the UI never
    //    flashes 0 while we wait on Health / network.
    final cached = _ledger.totalFor(_ledger.dayKey(DateTime.now()));
    if (cached > 0) _emit(cached);

    // 2. Decide local source: Health if available + permitted, else
    //    pedometer.
    if (await _useHealthIfAvailable()) {
      _source = StepSource.health;
    } else {
      await _useSensor();
    }

    // 3. Reconcile with backend in the background.
    unawaited(_reconcileWithBackend());
  }

  Future<void> stop() async {
    await _sensorSub?.cancel();
    _sensorSub = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _initialized = false;
    _initFuture = null;
  }

  /// Re-attempt the Health path. Call this after the user grants
  /// permission via the rationale dialog so we can switch from
  /// pedometer → health without an app restart.
  Future<void> retryHealth() async {
    if (_source == StepSource.health) return;
    try {
      if (!await _stepRepo.isHealthDataAvailable()) return;
      if (!await _stepRepo.hasHealthPermission()) return;

      await _sensorSub?.cancel();
      _sensorSub = null;
      _source = StepSource.health;
      await _refreshFromHealth();
      _startHealthPolling();
    } catch (e, s) {
      log('retryHealth failed: $e',
          name: 'StepCounterService', stackTrace: s);
    }
  }

  Future<void> dispose() async {
    await stop();
    await _subject.close();
  }

  // ── Health primary path ─────────────────────────────────────────────

  Future<bool> _useHealthIfAvailable() async {
    try {
      if (!await _stepRepo.isHealthDataAvailable()) return false;
      if (!await _stepRepo.hasHealthPermission()) return false;

      await _refreshFromHealth();
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

    // Health is always the BASE — it's authoritative for absolute totals.
    if (fresh > _base) {
      _base = fresh;
      _emit(_displayed());
    }
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

    // Day rollover.
    if (lastSavedDate != todayKey) {
      if (lastSensorTotal >= 0 && sensorTotal > lastSensorTotal) {
        await _ledger.addSteps(lastSavedDate, sensorTotal - lastSensorTotal);
      }
      await _ledger.setLastSensorDate(todayKey);
      await _ledger.setLastSensorTotal(sensorTotal);
      _base = 0;
      _emit(0);
      return;
    }

    // First read after install / reset — establish baseline.
    if (lastSensorTotal < 0) {
      await _ledger.setLastSensorTotal(sensorTotal);
      return;
    }

    // Reboot: device counter reset to 0.
    final delta = sensorTotal < lastSensorTotal
        ? sensorTotal
        : sensorTotal - lastSensorTotal;
    await _ledger.setLastSensorTotal(sensorTotal);
    if (delta <= 0) return;

    await _ledger.addSteps(todayKey, delta);
    _base = _ledger.totalFor(todayKey);
    _emit(_displayed());
  }

  // ── Backend reconciliation ──────────────────────────────────────────

  /// Fetches today's backend total. If it's higher than the local base,
  /// adopt it as the new base and persist that to the ledger so subsequent
  /// pedometer deltas accumulate on top.
  Future<void> _reconcileWithBackend() async {
    try {
      final backend = await _fetchBackendTotal();
      final local = _base;

      // Rule from the spec: if local is 0 OR local < backend, use backend
      // as the base.
      if (local == 0 || local < backend) {
        _base = backend;
        final todayKey = _ledger.dayKey(DateTime.now());
        await _ledger.ensureDayAtLeast(todayKey, backend, minSynced: backend);
        _emit(_displayed());
      }
    } catch (e, s) {
      log('Backend reconcile failed: $e',
          name: 'StepCounterService', stackTrace: s);
    }
  }

  Future<int> _fetchBackendTotal() async {
    try {
      final list = await _stepRepo.getSteps(0);
      if (list.isEmpty) return 0;
      return list.first.value.toInt();
    } catch (e) {
      log('Backend fetch failed: $e', name: 'StepCounterService');
      return 0;
    }
  }

  // ── Emission ────────────────────────────────────────────────────────

  int _displayed() => _base;

  void _emit(int total) {
    if (total < 0) total = 0;
    if (_subject.valueOrNull == total) return;
    _subject.add(total);

    // Mirror to the Android foreground notification — single writer, so
    // UI and notification can never disagree.
    if (Platform.isAndroid && StepsForegroundService.instance.isRunning) {
      unawaited(StepsForegroundService.instance.syncSteps(total));
    }
  }
}
