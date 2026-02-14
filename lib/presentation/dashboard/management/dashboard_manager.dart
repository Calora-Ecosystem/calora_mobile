import 'dart:async';
import 'dart:developer';

import 'package:calora/common/base/step_ledger_store.dart';
import 'package:calora/common/service/foreground_service.dart';
import 'package:calora/common/service/pedometer_service.dart';
import 'package:calora/common/widgets/stream/metrics_sync_bus.dart';
import 'package:calora/data/store/auth/auth_store.dart';
import 'package:calora/domain/model/dailies/steps_stat.dart';
import 'package:calora/domain/repo/step/step_repo.dart';
import 'package:calora/presentation/dashboard/management/dashboard_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class DashboardManager extends Manager<DashboardState, DashboardEffect> {
  final StepRepo _stepRepo;
  final PedometerService _pedometerService;
  final MetricsSyncService _metricsSync;
  final AuthStore _authStore;

  final StepLedgerStore _ledger = StepLedgerStore();

  StreamSubscription<int>? _stepsSub;
  Timer? _syncTimer;
  StreamSubscription<void>? _forceLogoutSub;

  int _lastSyncedTodaySteps = -1;
  bool _isSyncingToday = false;

  static const int MIN_DELTA_STEPS_TO_SEND = 20;
  static const Duration PERIODIC_SYNC_INTERVAL = Duration(minutes: 15);

  bool _initialized = false;
  Future<void>? _initFuture;

  DashboardManager(
    this._stepRepo,
    this._pedometerService,
    this._metricsSync,
    this._authStore,
  ) : super(const DashboardState());

  int get _todayTotal {
    final key = _ledger.dayKey(DateTime.now());
    return _ledger.totalFor(key);
  }

  @override
  void initialize() {
    super.initialize();
    if (_initialized) return;
    _initialized = true;
    _initFuture ??= _initializeInternal();
  }

  Future<void> _initializeInternal() async {
    try {
      _forceLogoutSub?.cancel();
      _forceLogoutSub = _authStore.onForceLogout.listen((_) async {
        _syncTimer?.cancel();
        await _stepsSub?.cancel();
        publish(const DashboardEffect.forceLogout());
      });
      await _startPedometerBootstrap();
    } catch (e, s) {
      log('[STEPS] CRITICAL: Error during DashboardManager initialization', name: 'DashboardManager', error: e, stackTrace: s);
    }
  }

  Future<void> _startPedometerBootstrap() async {
    try {
      log('[STEPS] Pedometer bootstrap started.', name: 'DashboardManager');
      await _pedometerService.initialize();
      if (!_pedometerService.isInitialized) {
        log('[STEPS] Pedometer service not initialized, aborting bootstrap.', name: 'DashboardManager');
        return;
      }

      // 1. Sync any data that was collected while the app was offline.
      await syncOfflineSteps();

      // 2. Get today's steps from the local ledger.
      final todayKey = _ledger.dayKey(DateTime.now());
      final total = _ledger.totalFor(todayKey);
      _lastSyncedTodaySteps = _ledger.syncedFor(todayKey);
      log('[STEPS] Bootstrap: Initial today total=$total, synced=$_lastSyncedTodaySteps', name: 'DashboardManager');


      // 3. Update UI and foreground service. The metrics will be updated AFTER sync.
      emit(state.copyWith(todaySteps: total));
      // No metrics update here, it happens after successful sync in _syncTodaySteps
      if (StepsForegroundService.instance.isRunning) {
        unawaited(StepsForegroundService.instance.syncSteps(total));
      }

      // 4. Start listening for live step updates and periodic syncs.
      _listenToStepUpdates();
      _startPeriodicSync();
      log('[STEPS] Pedometer bootstrap finished.', name: 'DashboardManager');
    } catch (e, s) {
      log('[STEPS] CRITICAL: Error during pedometer bootstrap', name: 'DashboardManager', error: e, stackTrace: s);
    }
  }

  void _listenToStepUpdates() {
    _stepsSub?.cancel();
    _stepsSub = _pedometerService.stepCountStream.listen(
      (sensorSteps) async {
        final lastSensorTotal = _ledger.getLastSensorTotal();
        await _ledger.setLastSensorTotal(sensorSteps);

        if (lastSensorTotal < 0) {
          log('[STEPS] First sensor reading ($sensorSteps). No delta to calculate.', name: 'DashboardManager');
          return;
        }

        int delta;
        if (sensorSteps < lastSensorTotal) {
          delta = sensorSteps;
          log('[STEPS] Reboot detected. Delta is new sensor value: $delta', name: 'DashboardManager');
        } else {
          delta = sensorSteps - lastSensorTotal;
        }

        if (delta <= 0) return;
        
        log('[STEPS] Delta calculated: $delta', name: 'DashboardManager');
        final todayKey = _ledger.dayKey(DateTime.now());
        await _ledger.addSteps(todayKey, delta);
        
        final newTotal = _ledger.totalFor(todayKey);
        emit(state.copyWith(todaySteps: newTotal));
        // Metrics update moved to _syncTodaySteps after successful backend sync

        if (StepsForegroundService.instance.isRunning) {
          unawaited(StepsForegroundService.instance.syncSteps(newTotal));
        }
      
        if (_shouldSyncToday(newTotal)) {
           log('[STEPS] Delta since last sync is >= $MIN_DELTA_STEPS_TO_SEND. Triggering sync.', name: 'DashboardManager');
          unawaited(_syncTodaySteps());
        } else {
           final stepsSinceSync = newTotal - _lastSyncedTodaySteps;
           log('[STEPS] Not syncing. Steps since last sync: $stepsSinceSync (threshold: $MIN_DELTA_STEPS_TO_SEND)', name: 'DashboardManager');
        }
      },
      onError: (e, s) {
        log('[STEPS] CRITICAL: Error in step count stream', name: 'DashboardManager', error: e, stackTrace: s);
      },
    );
  }

  bool _shouldSyncToday(int total) {
    if (total <= 0) return false;
    final delta = total - _lastSyncedTodaySteps;
    return delta >= MIN_DELTA_STEPS_TO_SEND;
  }

  Future<void> _syncTodaySteps({bool force = false}) async {
    if (_isSyncingToday) {
      log('[STEPS] Aborting sync for today: another sync is already in progress.', name: 'DashboardManager');
      return;
    }

    final total = _todayTotal;
    if (total <= _lastSyncedTodaySteps && !force) {
      log('[STEPS] Aborting sync for today: no new steps to send.', name: 'DashboardManager');
      return;
    }
    
    _isSyncingToday = true;
    log('[STEPS] Starting sync for today. Total: $total, Last Synced: $_lastSyncedTodaySteps', name: 'DashboardManager');

    try {
      final todayKey = _ledger.dayKey(DateTime.now());
      await _stepRepo.sendDailyData(metric: 'Step', value: total);
      await _ledger.setSynced(todayKey, total);
      _lastSyncedTodaySteps = total;
      _metricsSync.notifyUpdated(total); // <-- Metrics updated AFTER successful backend sync
      log('[STEPS] SUCCESS: Synced $total steps for today. Metrics updated.', name: 'DashboardManager');
    } catch(e, s) {
      log('[STEPS] FAILURE: Failed to sync today steps. Error: $e', name: 'DashboardManager', error: e, stackTrace: s);
    } finally {
      _isSyncingToday = false;
      log('[STEPS] Finished sync for today.', name: 'DashboardManager');
    }
  }

  Future<void> syncOfflineSteps() async {
    log('[STEPS] Starting offline sync process.', name: 'DashboardManager');
    final pendingDays = _ledger.getAllPendingDays();
    final todayKey = _ledger.dayKey(DateTime.now());
    
    final pastDaysToSync = pendingDays.where((key) => key != todayKey).toList();

    if (pastDaysToSync.isNotEmpty) {
      log('[STEPS] Found ${pastDaysToSync.length} past days to sync.', name: 'DashboardManager');
      try {
        final payload = pastDaysToSync.map((key) {
          return StepsWithMetricsRequest(
            date: DateTime.parse(key),
            value: _ledger.totalFor(key).toDouble(),
          );
        }).toList();

        await _stepRepo.sendStepDataDateRange(steps: payload);

        for (final dayKey in pastDaysToSync) {
          await _ledger.deleteDay(dayKey);
        }
        log('[STEPS] SUCCESS: Synced and cleared ${pastDaysToSync.length} past days.', name: 'DashboardManager');
      } catch (e, s) {
        log('[STEPS] FAILURE: Failed to sync offline steps. Error: $e', name: 'DashboardManager', error: e, stackTrace: s);
      }
    } else {
      log('[STEPS] No past days found to sync.', name: 'DashboardManager');
    }
    
    log('[STEPS] Forcing a sync for today as part of offline process.', name: 'DashboardManager');
    await _syncTodaySteps(force: true);
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(PERIODIC_SYNC_INTERVAL, (_) {
      log('[STEPS] Periodic sync timer triggered.', name: 'DashboardManager');
      unawaited(syncOfflineSteps());
    });
  }

  @override
  Future<void> close() {
    _syncTimer?.cancel();
    _stepsSub?.cancel();
    _forceLogoutSub?.cancel();
    return super.close();
  }
}
