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
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class DashboardManager extends Manager<DashboardState, DashboardEffect> with WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);
    _initFuture ??= _initializeInternal();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      log('[STEPS] App backgrounded/detached. Stopping live stream.', name: 'DashboardManager');
      _stepsSub?.cancel();
      _stepsSub = null;
    } else if (state == AppLifecycleState.resumed) {
      log('[STEPS] App resumed. Restarting live stream.', name: 'DashboardManager');
      _listenToStepUpdates();
      unawaited(_startPedometerBootstrap()); // Re-sync with backend on return
    }
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

      // 1. Fetch today's steps from backend to reconcile with local ledger.
      final todayKey = _ledger.dayKey(DateTime.now());
      try {
        log('[STEPS] Fetching today\'s steps from backend for reconciliation...', name: 'DashboardManager');
        final backendSteps = await _stepRepo.getSteps(0, offset: 0);
        int backendTotal = 0;
        if (backendSteps.isNotEmpty) {
          backendTotal = backendSteps.first.value.toInt();
        }
        
        final localTotal = _ledger.totalFor(todayKey);
        
        if (backendTotal > localTotal) {
          log('[STEPS] Backend has more steps ($backendTotal) than local ($localTotal). Updating local ledger.', name: 'DashboardManager');
          await _ledger.ensureDayAtLeast(todayKey, backendTotal, minSynced: backendTotal);
          _lastSyncedTodaySteps = backendTotal;
        } else if (localTotal == 0 && backendTotal == 0) {
          log('[STEPS] Both backend and local are 0 for today.', name: 'DashboardManager');
        } else {
          log('[STEPS] Local ledger ($localTotal) is ahead of or equal to backend ($backendTotal).', name: 'DashboardManager');
        }
      } catch (e, s) {
        log('[STEPS] Failed to fetch today\'s steps from backend for reconciliation.', name: 'DashboardManager', error: e, stackTrace: s);
      }

      // 2. Sync any data that was collected while the app was offline.
      await syncOfflineSteps();

      // 3. Get today's steps from the local ledger.
      final currentTotal = _ledger.totalFor(todayKey);
      _lastSyncedTodaySteps = _ledger.syncedFor(todayKey);
      log('[STEPS] Bootstrap: Final today total=$currentTotal, synced=$_lastSyncedTodaySteps', name: 'DashboardManager');

      // 4. Update UI and notify metrics system immediately
      emit(state.copyWith(todaySteps: currentTotal));
      _metricsSync.notifyUpdated(currentTotal); 
      
      if (StepsForegroundService.instance.isRunning) {
        unawaited(StepsForegroundService.instance.syncSteps(currentTotal));
      }

      // 5. Start listening for live step updates and periodic syncs.
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
        final now = DateTime.now();
        final todayKey = _ledger.dayKey(now);
        final lastSavedDate = _ledger.getLastSensorDate();
        final lastSensorTotal = _ledger.getLastSensorTotal();

        // 1. Detect Day Change
        if (lastSavedDate != todayKey) {
          log('[STEPS] Day change detected in stream: $lastSavedDate -> $todayKey', name: 'DashboardManager');
          
          // Save remaining delta to the OLD day before switching
          if (lastSensorTotal >= 0 && sensorSteps > lastSensorTotal) {
            final finalDelta = sensorSteps - lastSensorTotal;
            await _ledger.addSteps(lastSavedDate, finalDelta);
            log('[STEPS] Final delta $finalDelta added to old day $lastSavedDate', name: 'DashboardManager');
          }

          // Reset for the new day
          await _ledger.setLastSensorDate(todayKey);
          await _ledger.setLastSensorTotal(sensorSteps);
          _lastSyncedTodaySteps = 0;
          
          // Trigger sync for the finished day(s)
          unawaited(syncOfflineSteps());

          // Update UI for the new day
          emit(state.copyWith(todaySteps: 0));
          _metricsSync.notifyUpdated(0);
          if (StepsForegroundService.instance.isRunning) {
            unawaited(StepsForegroundService.instance.syncSteps(0));
          }
          return;
        }

        // 2. Normal live update (same day)
        await _ledger.setLastSensorTotal(sensorSteps);

        if (lastSensorTotal < 0) {
          log('[STEPS] First sensor reading ($sensorSteps). Initializing ledger.', name: 'DashboardManager');
          return;
        }

        int delta;
        if (sensorSteps < lastSensorTotal) {
          delta = sensorSteps; // Phone rebooted
          log('[STEPS] Reboot detected. Sensor reset to $sensorSteps', name: 'DashboardManager');
        } else {
          delta = sensorSteps - lastSensorTotal;
        }

        if (delta <= 0) return;

        log('[STEPS] Delta captured: $delta. Adding to $todayKey', name: 'DashboardManager');
        await _ledger.addSteps(todayKey, delta);
        
        final newTotal = _ledger.totalFor(todayKey);
        emit(state.copyWith(todaySteps: newTotal));

        if (StepsForegroundService.instance.isRunning) {
          unawaited(StepsForegroundService.instance.syncSteps(newTotal));
        }
      
        if (_shouldSyncToday(newTotal)) {
           log('[STEPS] Sync threshold met ($newTotal). Triggering backend sync.', name: 'DashboardManager');
           unawaited(_syncTodaySteps());
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
    WidgetsBinding.instance.removeObserver(this);
    _syncTimer?.cancel();
    _stepsSub?.cancel();
    _forceLogoutSub?.cancel();
    return super.close();
  }
}
