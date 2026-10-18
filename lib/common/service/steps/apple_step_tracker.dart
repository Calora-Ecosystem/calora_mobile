import 'dart:async';
import 'dart:developer';

import 'package:calora/common/base/step_ledger_db.dart';
import 'package:calora/common/service/pedometer_service.dart';
import 'package:calora/common/service/step_sync_service.dart';
import 'package:calora/common/service/steps/step_tracker.dart';
import 'package:calora/domain/repo/step/step_repo.dart';
import 'package:rxdart/rxdart.dart';

class AppleStepTracker implements StepTracker {
  AppleStepTracker(this._stepRepo, this._pedometer);

  final StepRepo _stepRepo;
  final PedometerService _pedometer;
  final StepLedgerDb _db = StepLedgerDb.instance;

  late final StepSyncService _syncService = StepSyncService(_stepRepo);

  static const Duration _pollInterval = Duration(seconds: 5);
  static const Duration _backendSyncInterval = Duration(minutes: 1);
  static const int _backfillDays = 30;

  final _subject = BehaviorSubject<int>.seeded(0);
  final _events = StreamController<StepCounterEvent>.broadcast();

  StreamSubscription<int>? _sensorSub;
  Timer? _pollTimer;
  Timer? _backendSyncTimer;
  StepSource _source = StepSource.none;
  String _activeDayKey = '';
  bool _initialized = false;
  Future<void>? _initFuture;
  Future<void> _sensorTickQueue = Future.value();

  @override
  Stream<int> get stream => _subject.stream;

  @override
  int get currentSteps => _subject.valueOrNull ?? 0;

  @override
  StepSource get source => _source;

  @override
  Stream<StepCounterEvent> get events => _events.stream;

  @override
  Future<void> start() => _initFuture ??= _startInternal();

  Future<void> _startInternal() async {
    if (_initialized) return;
    _initialized = true;

    final cached = await _db.totalFor(StepLedgerDb.dayKey(DateTime.now()));
    if (cached > 0) _emit(cached);

    if (await _useHealthIfAvailable()) {
      _source = StepSource.health;
      unawaited(_guard('Backfill', _backfillHistoricalDays));
    } else {
      await _fallbackToInProcessPedometer();
      unawaited(_guard('Pending sync', _syncService.syncPendingToBackend));
    }

    _startBackendSync();
  }

  @override
  Future<void> stop() async {
    await _sensorSub?.cancel();
    _sensorSub = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _backendSyncTimer?.cancel();
    _backendSyncTimer = null;
    _initialized = false;
    _initFuture = null;
  }

  @override
  Future<void> refresh() => retryHealth();

  @override
  Future<void> retryHealth() async {
    if (_source == StepSource.health) return;
    try {
      if (!await _stepRepo.isHealthDataAvailable()) return;

      final initial = await _stepRepo.getTodayHealthSteps();
      if (initial <= 0) return;

      await _sensorSub?.cancel();
      _sensorSub = null;
      _source = StepSource.health;

      final todayKey = StepLedgerDb.dayKey(DateTime.now());
      await _db.ensureDayAtLeast(todayKey, initial);
      _emit(initial);

      _startHealthPolling();
    } catch (e, s) {
      log('retryHealth failed: $e', name: 'AppleStepTracker', stackTrace: s);
    }
  }

  @override
  Future<void> forcePedometer() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    await _fallbackToInProcessPedometer();
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _subject.close();
    await _events.close();
  }

  bool _consumeDayRollover() {
    final todayKey = StepLedgerDb.dayKey(DateTime.now());
    if (_activeDayKey.isEmpty) {
      _activeDayKey = todayKey;
      return false;
    }
    if (_activeDayKey != todayKey) {
      _activeDayKey = todayKey;
      return true;
    }
    return false;
  }

  Future<bool> _useHealthIfAvailable() async {
    try {
      if (!await _stepRepo.isHealthDataAvailable()) return false;

      final initial = await _stepRepo.getTodayHealthSteps();
      if (initial <= 0) {
        log(
          'iOS Health probe returned 0 — using pedometer',
          name: 'AppleStepTracker',
        );
        return false;
      }

      final todayKey = StepLedgerDb.dayKey(DateTime.now());
      await _db.ensureDayAtLeast(todayKey, initial);
      _emit(initial);

      _startHealthPolling();
      return true;
    } catch (e, s) {
      log(
        'Health activation failed: $e',
        name: 'AppleStepTracker',
        stackTrace: s,
      );
      return false;
    }
  }

  Future<void> _refreshFromHealth() async {
    final rolled = _consumeDayRollover();
    final fresh = await _stepRepo.getTodayHealthSteps();
    final todayKey = StepLedgerDb.dayKey(DateTime.now());

    if (rolled) {
      await _db.ensureDayAtLeast(todayKey, fresh);
      _emit(fresh);
      return;
    }

    if (fresh <= 0) return;
    await _db.ensureDayAtLeast(todayKey, fresh);
    _emit(fresh);
  }

  void _startHealthPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      try {
        await _refreshFromHealth();
      } catch (e) {
        log('Health poll error: $e', name: 'AppleStepTracker');
      }
    });
  }

  Future<void> _guard(String label, Future<void> Function() action) async {
    try {
      await action();
    } catch (e, s) {
      log('$label failed: $e', name: 'AppleStepTracker', stackTrace: s);
    }
  }

  Future<void> _fallbackToInProcessPedometer() async {
    await _pedometer.initialize();
    if (!_pedometer.isInitialized) {
      _source = StepSource.none;
      _emit(await _db.totalFor(StepLedgerDb.dayKey(DateTime.now())));
      return;
    }
    _source = StepSource.pedometer;
    _listenToSensor();
  }

  void _listenToSensor() {
    _sensorSub?.cancel();
    _sensorSub = _pedometer.stepCountStream.listen((sensorTotal) {
      _sensorTickQueue = _sensorTickQueue.then(
        (_) => _onSensorTick(sensorTotal),
        onError: (_) => _onSensorTick(sensorTotal),
      );
    }, onError: (e) => log('Pedometer error: $e', name: 'AppleStepTracker'));
  }

  Future<void> _onSensorTick(int sensorTotal) async {
    final todayKey = StepLedgerDb.dayKey(DateTime.now());
    final lastSavedDate = await _db.getLastSensorDate();
    final lastSensorTotal = await _db.getLastSensorTotal();

    if (lastSavedDate != todayKey) {
      if (lastSensorTotal >= 0 && sensorTotal > lastSensorTotal) {
        await _db.addSteps(lastSavedDate, sensorTotal - lastSensorTotal);
      }
      await _db.setLastSensorDate(todayKey);
      await _db.setLastSensorTotal(sensorTotal);
      _emit(0);
      return;
    }

    if (lastSensorTotal < 0) {
      await _db.setLastSensorTotal(sensorTotal);
      return;
    }

    final delta = sensorTotal < lastSensorTotal
        ? sensorTotal
        : sensorTotal - lastSensorTotal;
    await _db.setLastSensorTotal(sensorTotal);
    if (delta <= 0) return;

    await _db.addSteps(todayKey, delta);
    _emit(await _db.totalFor(todayKey));
  }

  Future<void> _backfillHistoricalDays() async {
    log('Backfill starting ($_backfillDays days)…', name: 'AppleStepTracker');
    await _syncService.hydrateHealthHistory(days: _backfillDays);
    await _syncService.syncPendingToBackend();
  }

  void _startBackendSync() {
    _backendSyncTimer?.cancel();
    _backendSyncTimer = Timer.periodic(
      _backendSyncInterval,
      (_) => unawaited(_guard('Backend sync', _pushToBackend)),
    );
  }

  Future<void> _pushToBackend() async {
    final steps = currentSteps;
    if (steps > 0) {
      await _db.ensureDayAtLeast(StepLedgerDb.dayKey(DateTime.now()), steps);
    }
    await _syncService.syncPendingToBackend();
  }

  void _emit(int total) {
    if (total < 0) total = 0;
    if (_subject.valueOrNull == total) return;
    _subject.add(total);
  }
}
