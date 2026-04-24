// lib/presentation/dashboard/management/dashboard_manager.dart

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:calora/common/base/step_ledger_store.dart';
import 'package:calora/common/service/foreground_service.dart';
import 'package:calora/common/service/installed_health_apps_service.dart';
import 'package:calora/common/service/pedometer_service.dart';
import 'package:calora/common/widgets/stream/metrics_sync_bus.dart';
import 'package:calora/data/store/auth/auth_store.dart';
import 'package:calora/domain/model/dailies/steps_stat.dart';
import 'package:calora/domain/repo/step/step_repo.dart';
import 'package:calora/presentation/dashboard/management/dashboard_management.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

enum StepMode {
  /// Health Connect (Android) / HealthKit (iOS) is the source of truth.
  healthOnly,

  /// Local pedometer sensor is the source of truth.
  pedometerOnly,

  /// Neither source is usable.
  none,
}

@injectable
class DashboardManager extends Manager<DashboardState, DashboardEffect>
    with WidgetsBindingObserver {
  final StepRepo _stepRepo;
  final PedometerService _pedometerService;
  final MetricsSyncService _metricsSync;
  final AuthStore _authStore;

  final StepLedgerStore _ledger = StepLedgerStore();

  StreamSubscription<int>? _stepsSub;
  StreamSubscription<void>? _forceLogoutSub;
  Timer? _syncTimer;
  Timer? _safetyNetTimer;

  StepMode _mode = StepMode.none;
  int _pedometerSteps = 0;
  int _healthSteps = 0;

  /// Tracks whether the silent pedometer safety-net has taken over the
  /// display because Health is reporting ~0 while the sensor is counting.
  bool _safetyNetEngaged = false;

  int _lastSyncedTodaySteps = -1;
  bool _isSyncingToday = false;
  DateTime _lastBackendSyncTime = DateTime.fromMillisecondsSinceEpoch(0);

  bool _initialized = false;
  Future<void>? _initFuture;

  static const Duration HEALTH_POLL_INTERVAL = Duration(seconds: 5);
  static const Duration BACKEND_SYNC_INTERVAL = Duration(seconds: 30);
  static const Duration SAFETY_NET_CHECK_DELAY = Duration(minutes: 10);
  static const int MIN_DELTA_STEPS_TO_SEND = 20;
  static const int SAFETY_NET_PEDOMETER_MIN = 500;
  static const int SAFETY_NET_HEALTH_MAX = 100;

  DashboardManager(
    this._stepRepo,
    this._pedometerService,
    this._metricsSync,
    this._authStore,
  ) : super(const DashboardState());

  // ─────────────────────────────────────────────────────────────────────
  // Derived state
  // ─────────────────────────────────────────────────────────────────────

  int get _displayedSteps {
    switch (_mode) {
      case StepMode.healthOnly:
        // Safety net: if Health is suspiciously empty while the sensor is
        // counting, show the pedometer number instead. Still "healthOnly"
        // mode — we don't nag the user, we just don't let them see 0.
        if (_safetyNetEngaged && _pedometerSteps > _healthSteps) {
          return _pedometerSteps;
        }
        return _healthSteps;
      case StepMode.pedometerOnly:
        return _pedometerSteps;
      case StepMode.none:
        return 0;
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────────

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
      _stepsSub?.cancel();
      _stepsSub = null;
      _syncTimer?.cancel();
      return;
    }

    if (state == AppLifecycleState.resumed) {
      // If the user came back from opening the device Health settings,
      // re-check whether permission is now granted.
      if (_ledger.didUserOpenHealthApp()) {
        unawaited(_recheckAfterUserReturn());
      } else {
        _resumeLiveTracking();
      }
      unawaited(syncOfflineSteps());
    }
  }

  void _resumeLiveTracking() {
    if (_mode == StepMode.healthOnly) {
      _startHealthPolling();
      // If we had engaged the safety net, keep the pedometer stream alive too.
      if (_safetyNetEngaged && _pedometerService.isInitialized) {
        _listenToStepUpdates();
      }
    }
    if (_mode == StepMode.pedometerOnly && _pedometerService.isInitialized) {
      _listenToStepUpdates();
    }
  }

  Future<void> _initializeInternal() async {
    try {
      _forceLogoutSub?.cancel();
      _forceLogoutSub = _authStore.onForceLogout.listen((_) async {
        _syncTimer?.cancel();
        _safetyNetTimer?.cancel();
        await _stepsSub?.cancel();
        await StepsForegroundService.instance.stop();
        publish(const DashboardEffect.forceLogout());
      });
      await _startStepCounter();
    } catch (e) {
      log('DashboardManager _initializeInternal error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Entry point — linear flow per user spec
  //   1. Is the Health repo available? → no: pedometer.
  //   2. Have permission? → yes: fetch from Health.
  //   3. No permission → emit rationale dialog effect. UI decides
  //      onUserAcceptedHealthPermission / onUserDeclinedHealthPermission.
  // ─────────────────────────────────────────────────────────────────────

  Future<void> _startStepCounter() async {
    try {
      final healthAvailable = await _stepRepo.isHealthDataAvailable();

      if (!healthAvailable) {
        log('Health repo unavailable → PEDOMETER_ONLY', name: 'DashboardManager');
        await _switchToPedometer();
        return;
      }

      // Android reports read-permission status accurately — use it as the
      // fast path. iOS HealthKit never reports READ status back to the app
      // (Apple privacy model), so `hasHealthPermission()` returns false
      // there on every launch even when access is granted.
      if (await _stepRepo.hasHealthPermission()) {
        log('Health permission already granted → HEALTH_ONLY', name: 'DashboardManager');
        await _switchToHealth();
        return;
      }

      // Respect a previously-remembered rationale choice so we never
      // re-prompt on every cold start (the original bug on iOS).
      if (_ledger.isHealthHintDismissed()) {
        log('User previously declined health rationale → PEDOMETER_ONLY',
            name: 'DashboardManager');
        await _switchToPedometer();
        return;
      }
      if (_ledger.isHealthHintShown()) {
        log('User previously accepted health rationale → HEALTH_ONLY',
            name: 'DashboardManager');
        // iOS: harmless no-op if already resolved; on Android this is
        // only reached if the permission was revoked after acceptance,
        // in which case the OS will re-prompt.
        unawaited(_stepRepo.requestHealthPermission());
        await _switchToHealth();
        return;
      }

      // First launch — show the rationale dialog and wait for the user.
      final detectedApp = Platform.isAndroid
          ? (await InstalledHealthAppsService.detectPrimaryHealthApp() ?? 'unknown')
          : 'ios';

      log('No health permission → prompting dialog', name: 'DashboardManager');
      publish(DashboardEffect.requestHealthPermission(detectedApp: detectedApp));
    } catch (e, s) {
      log('_startStepCounter error: $e', stackTrace: s);
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // UI callbacks (driven from DashboardPage)
  // ─────────────────────────────────────────────────────────────────────

  /// User tapped "Yes" on the rationale dialog.
  Future<void> onUserAcceptedHealthPermission() async {
    // Remember the rationale choice so we never re-prompt on next launch.
    // Critical on iOS, since HealthKit won't report READ status back to us.
    await _ledger.setHealthHintShown();

    final granted = await _stepRepo.requestHealthPermission();
    if (granted) {
      log('System permission granted → HEALTH_ONLY', name: 'DashboardManager');
      await _switchToHealth();
      return;
    }

    // iOS: `requestAuthorization` can return false even after grant. Trust
    // the user's dialog acceptance and activate Health anyway.
    if (Platform.isIOS) {
      log('iOS — activating Health (hasPermissions unreliable)',
          name: 'DashboardManager');
      await _switchToHealth();
      return;
    }

    // Android: system prompt was denied. Send the user to the device
    // settings so they can grant it manually.
    log('System permission denied — opening device health settings',
        name: 'DashboardManager');
    await _ledger.setUserOpenedHealthApp(true);
    await _stepRepo.openHealthSettings();
  }

  /// User tapped "No" on the rationale dialog.
  Future<void> onUserDeclinedHealthPermission() async {
    await _ledger.setHealthHintDismissed();
    log('User declined health permission → PEDOMETER_ONLY', name: 'DashboardManager');
    await _switchToPedometer();
  }

  /// Called when the user returns to the app after we sent them to the
  /// device health settings. Re-checks permission and either switches to
  /// Health or falls back to the pedometer.
  Future<void> _recheckAfterUserReturn() async {
    await _ledger.setUserOpenedHealthApp(false);
    // Give Health Connect a moment to propagate the new grant.
    await Future.delayed(const Duration(seconds: 2));

    // iOS HealthKit never reports READ status back, so on iOS we assume
    // the user granted from the settings screen they just visited.
    if (Platform.isIOS) {
      await _switchToHealth();
      return;
    }

    final granted = await _stepRepo.hasHealthPermission();
    if (granted) {
      log('Permission granted after settings return → HEALTH_ONLY', name: 'DashboardManager');
      await _switchToHealth();
    } else {
      log('Permission still denied after settings return → PEDOMETER_ONLY', name: 'DashboardManager');
      await _switchToPedometer();
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Mode switching
  // ─────────────────────────────────────────────────────────────────────

  Future<void> _switchToHealth() async {
    _mode = StepMode.healthOnly;
    _safetyNetEngaged = false;

    _healthSteps = await _stepRepo.getTodayHealthSteps();

    int backendTotal = await _fetchBackendTotal();
    await syncOfflineSteps();

    int currentTotal = _displayedSteps;
    if (backendTotal > currentTotal) currentTotal = backendTotal;

    final todayKey = _ledger.dayKey(DateTime.now());
    _lastSyncedTodaySteps = _ledger.syncedFor(todayKey);

    emit(state.copyWith(todaySteps: currentTotal));
    _metricsSync.notifyUpdated(currentTotal);

    _startHealthPolling();
    _scheduleSafetyNetCheck();
  }

  Future<void> _switchToPedometer() async {
    _mode = StepMode.pedometerOnly;
    _safetyNetEngaged = false;
    _safetyNetTimer?.cancel();
    _syncTimer?.cancel();

    await _pedometerService.initialize();
    if (!_pedometerService.isInitialized) {
      log('Pedometer init failed — mode=none', name: 'DashboardManager');
      _mode = StepMode.none;
      emit(state.copyWith(todaySteps: 0));
      return;
    }

    final todayKey = _ledger.dayKey(DateTime.now());
    _pedometerSteps = _ledger.totalFor(todayKey);

    int backendTotal = await _fetchBackendTotal();
    await syncOfflineSteps();

    int currentTotal = _displayedSteps;
    if (backendTotal > currentTotal) currentTotal = backendTotal;

    _lastSyncedTodaySteps = _ledger.syncedFor(todayKey);

    emit(state.copyWith(todaySteps: currentTotal));
    _metricsSync.notifyUpdated(currentTotal);

    await _startForegroundServiceIfNeeded(currentTotal);
    _listenToStepUpdates();
  }

  // ─────────────────────────────────────────────────────────────────────
  // Silent pedometer safety net
  //
  // If Health permission is granted but Health is still reporting ~0 after
  // a grace period (e.g. user hasn't linked Samsung Health / Google Fit to
  // Health Connect), silently spin up the pedometer and show the larger of
  // the two values. Never nags the user.
  // ─────────────────────────────────────────────────────────────────────

  void _scheduleSafetyNetCheck() {
    _safetyNetTimer?.cancel();
    _safetyNetTimer = Timer(SAFETY_NET_CHECK_DELAY, () async {
      if (_mode != StepMode.healthOnly) return;
      if (_safetyNetEngaged) return;

      try {
        _healthSteps = await _stepRepo.getTodayHealthSteps();
      } catch (_) {}

      if (_healthSteps >= SAFETY_NET_HEALTH_MAX) {
        // Health is working fine — nothing to do.
        return;
      }

      log('Safety net: Health=$_healthSteps — engaging silent pedometer',
          name: 'DashboardManager');
      await _engagePedometerSafetyNet();
    });
  }

  Future<void> _engagePedometerSafetyNet() async {
    await _pedometerService.initialize();
    if (!_pedometerService.isInitialized) return;

    _safetyNetEngaged = true;

    final todayKey = _ledger.dayKey(DateTime.now());
    _pedometerSteps = _ledger.totalFor(todayKey);

    await _startForegroundServiceIfNeeded(_displayedSteps);
    _listenToStepUpdates();
    _emitCurrentSteps();
  }

  // ─────────────────────────────────────────────────────────────────────
  // Health polling
  // ─────────────────────────────────────────────────────────────────────

  void _startHealthPolling() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(HEALTH_POLL_INTERVAL, (_) async {
      try {
        _healthSteps = await _stepRepo.getTodayHealthSteps();

        // If Health catches up and reports real data, we can drop the
        // safety net again.
        if (_safetyNetEngaged && _healthSteps >= SAFETY_NET_HEALTH_MAX) {
          log('Safety net: Health recovered ($_healthSteps) — disengaging',
              name: 'DashboardManager');
          _safetyNetEngaged = false;
          _stepsSub?.cancel();
          _stepsSub = null;
          await StepsForegroundService.instance.stop();
        }

        _emitCurrentSteps();

        final now = DateTime.now();
        final shouldSend =
            _shouldSyncToday(_displayedSteps) &&
            now.difference(_lastBackendSyncTime) >= BACKEND_SYNC_INTERVAL;
        if (shouldSend) {
          unawaited(_syncTodaySteps());
        }
      } catch (e) {
        log('Health polling error: $e');
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────
  // Pedometer stream listener
  // ─────────────────────────────────────────────────────────────────────

  void _listenToStepUpdates() {
    _stepsSub?.cancel();
    _stepsSub = _pedometerService.stepCountStream.listen(
      (sensorSteps) async {
        final now = DateTime.now();
        final todayKey = _ledger.dayKey(now);
        final lastSavedDate = _ledger.getLastSensorDate();
        final lastSensorTotal = _ledger.getLastSensorTotal();

        // New day rollover
        if (lastSavedDate != todayKey) {
          if (lastSensorTotal >= 0 && sensorSteps > lastSensorTotal) {
            final finalDelta = sensorSteps - lastSensorTotal;
            await _ledger.addSteps(lastSavedDate, finalDelta);
          }
          await _ledger.setLastSensorDate(todayKey);
          await _ledger.setLastSensorTotal(sensorSteps);
          _pedometerSteps = 0;
          _lastSyncedTodaySteps = 0;
          unawaited(syncOfflineSteps());
          _emitCurrentSteps();
          return;
        }

        // First read — establish the baseline.
        if (lastSensorTotal < 0) {
          await _ledger.setLastSensorTotal(sensorSteps);
          return;
        }

        int delta;
        if (sensorSteps < lastSensorTotal) {
          // Device reboot: sensor counter restarted from 0.
          delta = sensorSteps;
        } else {
          delta = sensorSteps - lastSensorTotal;
        }

        await _ledger.setLastSensorTotal(sensorSteps);
        if (delta <= 0) return;

        await _ledger.addSteps(todayKey, delta);
        _pedometerSteps = _ledger.totalFor(todayKey);

        // If we're in healthOnly mode and the pedometer has raced ahead
        // of a stalled Health reading, engage the safety net so the UI
        // doesn't show stale zeros.
        if (_mode == StepMode.healthOnly &&
            !_safetyNetEngaged &&
            _pedometerSteps >= SAFETY_NET_PEDOMETER_MIN &&
            _healthSteps < SAFETY_NET_HEALTH_MAX) {
          _safetyNetEngaged = true;
          log('Safety net engaged via stream (ped=$_pedometerSteps, health=$_healthSteps)',
              name: 'DashboardManager');
        }

        _emitCurrentSteps();

        if (_shouldSyncToday(_displayedSteps)) {
          unawaited(_syncTodaySteps());
        }
      },
      onError: (e) => log('Pedometer stream error: $e'),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // UI update
  // ─────────────────────────────────────────────────────────────────────

  void _emitCurrentSteps() {
    final total = _displayedSteps;
    if (total == state.todaySteps) return;

    emit(state.copyWith(todaySteps: total));
    _metricsSync.notifyUpdated(total);

    if (StepsForegroundService.instance.isRunning) {
      unawaited(StepsForegroundService.instance.syncSteps(total));
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Backend sync
  // ─────────────────────────────────────────────────────────────────────

  Future<int> _fetchBackendTotal() async {
    try {
      final backendSteps = await _stepRepo.getSteps(0);
      if (backendSteps.isNotEmpty) {
        return backendSteps.first.value.toInt();
      }
    } catch (e) {
      log('Backend steps fetch failed: $e');
    }
    return 0;
  }

  bool _shouldSyncToday(int total) {
    if (total <= 0) return false;
    final delta = total - _lastSyncedTodaySteps;
    return delta >= MIN_DELTA_STEPS_TO_SEND;
  }

  Future<void> _syncTodaySteps() async {
    if (_isSyncingToday) return;
    _isSyncingToday = true;

    try {
      final currentSteps = _displayedSteps;

      // Guard: never overwrite the backend with 0 — on cold start, Health
      // Connect can briefly return 0 before Samsung Health / Google Fit
      // finishes propagating today's data, and that 0 would wipe a real value.
      if (currentSteps > 0 && currentSteps > _lastSyncedTodaySteps) {
        final todayKey = _ledger.dayKey(DateTime.now());
        await _stepRepo.sendDailyData(metric: 'Step', value: currentSteps);
        await _ledger.setSynced(todayKey, currentSteps);
        _lastSyncedTodaySteps = currentSteps;
        _lastBackendSyncTime = DateTime.now();
      }
    } catch (e) {
      log('_syncTodaySteps error: $e');
    } finally {
      _isSyncingToday = false;
    }
  }

  Future<void> syncOfflineSteps() async {
    final pendingDays = _ledger.getAllPendingDays();
    final todayKey = _ledger.dayKey(DateTime.now());
    final pastDaysToSync = pendingDays.where((key) => key != todayKey).toList();

    if (pastDaysToSync.isNotEmpty) {
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
      } catch (e) {
        log('syncOfflineSteps error: $e');
      }
    }

    if (_mode == StepMode.healthOnly) {
      try {
        final datePeriod = (_stepRepo as dynamic).getDatePeriods(2, 0) as Map<String, DateTime>;
        await _stepRepo.sendHealthData(
          from: datePeriod['from']!,
          to: datePeriod['to']!,
        );
      } catch (e) {
        log('sendHealthData error: $e');
      }
    }

    await _syncTodaySteps();
  }

  // ─────────────────────────────────────────────────────────────────────
  // Foreground service
  // ─────────────────────────────────────────────────────────────────────

  Future<void> _startForegroundServiceIfNeeded(int currentSteps) async {
    if (!Platform.isAndroid) return;
    if (StepsForegroundService.instance.isRunning) {
      unawaited(StepsForegroundService.instance.syncSteps(currentSteps));
      return;
    }

    // TODO: goal va weight'ni profileStore'dan oling
    StepsForegroundService.instance.setGoalSteps(10000);
    StepsForegroundService.instance.setUserWeight(70.0);

    final started = await StepsForegroundService.instance.start();
    if (started) {
      unawaited(StepsForegroundService.instance.syncSteps(currentSteps));
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Close
  // ─────────────────────────────────────────────────────────────────────

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _syncTimer?.cancel();
    _safetyNetTimer?.cancel();
    _stepsSub?.cancel();
    _forceLogoutSub?.cancel();
    return super.close();
  }
}
