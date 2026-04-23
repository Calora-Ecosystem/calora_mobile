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
  /// Faqat Health (iOS default yoki Android + Samsung Health ulangan)
  healthOnly,

  /// Faqat pedometer (Android + Health Connect yo'q/ruxsatsiz)
  pedometerOnly,

  /// Android: Health va pedometer birga, max() ko'rsatiladi
  hybrid,

  /// Hech qanday manba ishlamaydi (iOS + HealthKit ruxsatsiz)
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
  Timer? _hintTimer;

  StepMode _mode = StepMode.none;
  int _pedometerSteps = 0;
  int _healthSteps = 0;

  int _lastSyncedTodaySteps = -1;
  bool _isSyncingToday = false;
  DateTime _lastBackendSyncTime = DateTime.fromMillisecondsSinceEpoch(0);

  bool _initialized = false;
  Future<void>? _initFuture;

  static const Duration HEALTH_POLL_INTERVAL = Duration(seconds: 5);
  static const Duration BACKEND_SYNC_INTERVAL = Duration(seconds: 30);
  static const Duration HINT_DELAY = Duration(hours: 1);
  static const int MIN_DELTA_STEPS_TO_SEND = 20;
  static const int HINT_TRIGGER_PEDOMETER_MIN = 500;
  static const int HINT_TRIGGER_HEALTH_MAX = 100;
  static const int HEALTH_SWITCH_THRESHOLD = 500;

  DashboardManager(
    this._stepRepo,
    this._pedometerService,
    this._metricsSync,
    this._authStore,
  ) : super(const DashboardState());

  // ─────────────────────────────────────────────────────────────────────
  // Derived state
  // ─────────────────────────────────────────────────────────────────────

  /// Ekranga ko'rsatiladigan qadam — rejimga bog'liq
  int get _displayedSteps {
    switch (_mode) {
      case StepMode.hybrid:
        return _healthSteps > _pedometerSteps ? _healthSteps : _pedometerSteps;
      case StepMode.healthOnly:
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
      // Agar foydalanuvchi Health app'iga ketib qaytgan bo'lsa — qayta tekshiramiz
      if (_ledger.didUserOpenHealthApp()) {
        unawaited(_recheckAfterUserReturn());
      } else {
        _resumeLiveTracking();
      }
      unawaited(syncOfflineSteps());
    }
  }

  void _resumeLiveTracking() {
    if (_mode == StepMode.hybrid || _mode == StepMode.healthOnly) {
      _startHealthPolling();
    }
    if (_mode == StepMode.hybrid || _mode == StepMode.pedometerOnly) {
      if (_pedometerService.isInitialized) {
        _listenToStepUpdates();
      }
    }
  }

  Future<void> _initializeInternal() async {
    try {
      _forceLogoutSub?.cancel();
      _forceLogoutSub = _authStore.onForceLogout.listen((_) async {
        _syncTimer?.cancel();
        _hintTimer?.cancel();
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
  // Entry point — rejimni aniqlash
  // ─────────────────────────────────────────────────────────────────────

  Future<void> _startStepCounter() async {
    try {
      final healthAvailable = await _stepRepo.isHealthDataAvailable();
      final healthAuthorized = healthAvailable ? await _stepRepo.ensureHealthAuthorized() : false;

      if (Platform.isIOS) {
        await _runIosFlow(healthAuthorized);
      } else if (Platform.isAndroid) {
        await _runAndroidFlow(healthAuthorized);
      }
    } catch (e, s) {
      log('_startStepCounter error: $e', stackTrace: s);
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // iOS flow — sodda
  // ─────────────────────────────────────────────────────────────────────

  Future<void> _runIosFlow(bool healthAuthorized) async {
    if (!healthAuthorized) {
      _mode = StepMode.none;
      log('iOS: HealthKit permission denied', name: 'DashboardManager');
      emit(state.copyWith(todaySteps: 0));
      publish(const DashboardEffect.healthPermissionRequired());
      return;
    }

    _mode = StepMode.healthOnly;
    log('iOS: HEALTH_ONLY mode', name: 'DashboardManager');
    await _runHealthOnlyFlow();
  }

  // ─────────────────────────────────────────────────────────────────────
  // Android flow — sekvensial mantiq
  // ─────────────────────────────────────────────────────────────────────

  Future<void> _runAndroidFlow(bool healthAuthorized) async {
    // 1. Health Connect yo'q yoki ruxsat berilmagan → pedometer
    if (!healthAuthorized) {
      _mode = StepMode.pedometerOnly;
      log('Android: PEDOMETER_ONLY (Health unavailable/denied)', name: 'DashboardManager');
      await _runPedometerFlow();
      return;
    }

    // 2. Health'dan boshlang'ich qiymatni olamiz
    _healthSteps = await _stepRepo.getTodayHealthSteps();
    log('Android: initial Health steps = $_healthSteps', name: 'DashboardManager');

    // 3. Foydalanuvchi oldin "Keyinroq" bosganmi? → gibrid rejimga
    if (_ledger.isHealthHintDismissed()) {
      _mode = StepMode.hybrid;
      log('Android: HYBRID (hint was dismissed previously)', name: 'DashboardManager');
      await _runHybridFlow();
      return;
    }

    // 4. Foydalanuvchi Health app'ni ochib qaytib kelgan — qayta tekshiramiz
    if (_ledger.didUserOpenHealthApp()) {
      await _ledger.setUserOpenedHealthApp(false);
      await Future.delayed(const Duration(seconds: 5));
      _healthSteps = await _stepRepo.getTodayHealthSteps();
      log('Android: after user returned, Health = $_healthSteps', name: 'DashboardManager');

      if (_healthSteps >= HEALTH_SWITCH_THRESHOLD) {
        _mode = StepMode.healthOnly;
        log('Android: HEALTH_ONLY (connection worked)', name: 'DashboardManager');
        await _runHealthOnlyFlow();
        return;
      }

      // Hali ham yo'q — gibridga tushamiz va dismissed deb belgilaymiz
      await _ledger.setHealthHintDismissed();
      _mode = StepMode.hybrid;
      await _runHybridFlow();
      return;
    }

    // 5. Health'da ma'lumot bor — faqat Health rejimida ishlaymiz
    if (_healthSteps > 0) {
      _mode = StepMode.healthOnly;
      log('Android: HEALTH_ONLY (data available)', name: 'DashboardManager');
      await _runHealthOnlyFlow();
      return;
    }

    // 6. Health 0 qaytardi — gibrid rejimni yoqib, 1 soat kutib hint ko'rsatamiz
    _mode = StepMode.hybrid;
    log('Android: HYBRID (waiting 1h before hint)', name: 'DashboardManager');
    await _runHybridFlow();
    _scheduleHintCheck();
  }

  // ─────────────────────────────────────────────────────────────────────
  // Rejim implementatsiyalari
  // ─────────────────────────────────────────────────────────────────────

  Future<void> _runHealthOnlyFlow() async {
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
  }

  Future<void> _runPedometerFlow() async {
    await _pedometerService.initialize();
    if (!_pedometerService.isInitialized) {
      log('Pedometer init failed', name: 'DashboardManager');
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

  Future<void> _runHybridFlow() async {
    await _pedometerService.initialize();
    if (!_pedometerService.isInitialized) {
      log(
        'Pedometer init failed in hybrid — falling back to HEALTH_ONLY',
        name: 'DashboardManager',
      );
      _mode = StepMode.healthOnly;
      await _runHealthOnlyFlow();
      return;
    }

    final todayKey = _ledger.dayKey(DateTime.now());
    _pedometerSteps = _ledger.totalFor(todayKey);
    _healthSteps = await _stepRepo.getTodayHealthSteps();

    int backendTotal = await _fetchBackendTotal();
    await syncOfflineSteps();

    int currentTotal = _displayedSteps;
    if (backendTotal > currentTotal) currentTotal = backendTotal;

    _lastSyncedTodaySteps = _ledger.syncedFor(todayKey);

    emit(state.copyWith(todaySteps: currentTotal));
    _metricsSync.notifyUpdated(currentTotal);

    await _startForegroundServiceIfNeeded(currentTotal);
    _listenToStepUpdates();
    _startHealthPolling();
  }

  // ─────────────────────────────────────────────────────────────────────
  // Health polling
  // ─────────────────────────────────────────────────────────────────────

  void _startHealthPolling() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(HEALTH_POLL_INTERVAL, (_) async {
      try {
        _healthSteps = await _stepRepo.getTodayHealthSteps();
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

        // Yangi kun boshlandi
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

        // Birinchi o'qish — baseline o'rnatamiz
        if (lastSensorTotal < 0) {
          await _ledger.setLastSensorTotal(sensorSteps);
          return;
        }

        // Delta hisoblash
        int delta;
        if (sensorSteps < lastSensorTotal) {
          // Reboot: sensor 0'dan boshlandi
          delta = sensorSteps;
        } else {
          delta = sensorSteps - lastSensorTotal;
        }

        await _ledger.setLastSensorTotal(sensorSteps);
        if (delta <= 0) return;

        await _ledger.addSteps(todayKey, delta);
        _pedometerSteps = _ledger.totalFor(todayKey);
        _emitCurrentSteps();

        if (_shouldSyncToday(_displayedSteps)) {
          unawaited(_syncTodaySteps());
        }
      },
      onError: (e) => log('Pedometer stream error: $e'),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // UI yangilash
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
  // Samsung Health hint mantiqi
  // ─────────────────────────────────────────────────────────────────────

  void _scheduleHintCheck() {
    if (_ledger.isHealthHintShown()) return;

    _hintTimer?.cancel();
    _hintTimer = Timer(HINT_DELAY, () async {
      if (_ledger.isHealthHintShown()) return;
      if (_mode != StepMode.hybrid) return;

      _healthSteps = await _stepRepo.getTodayHealthSteps();
      log('Hint check: pedometer=$_pedometerSteps, health=$_healthSteps', name: 'DashboardManager');

      // Pedometer ko'p qadam sanagan, lekin Health hali 0 —
      // demak Samsung Health ulanmagan
      if (_pedometerSteps >= HINT_TRIGGER_PEDOMETER_MIN && _healthSteps < HINT_TRIGGER_HEALTH_MAX) {
        await _ledger.setHealthHintShown();
        final detectedApp = await InstalledHealthAppsService.detectPrimaryHealthApp();
        publish(
          DashboardEffect.suggestConnectHealthApp(
            detectedApp: detectedApp ?? 'unknown',
          ),
        );
      }
    });
  }

  /// UI'dan chaqiriladi: foydalanuvchi "Ochish" bosdi
  Future<void> onUserOpenedHealthApp() async {
    await _ledger.setUserOpenedHealthApp(true);
    log('User chose to open Health app', name: 'DashboardManager');
  }

  /// UI'dan chaqiriladi: foydalanuvchi "Keyinroq" bosdi
  Future<void> onUserDismissedHealthHint() async {
    await _ledger.setHealthHintDismissed();
    log('User dismissed health hint — staying in hybrid mode', name: 'DashboardManager');
  }

  /// Foydalanuvchi Health app'dan qaytib kelganda chaqiriladi
  Future<void> _recheckAfterUserReturn() async {
    log('User returned from Health app — rechecking', name: 'DashboardManager');
    await _ledger.setUserOpenedHealthApp(false);

    // Samsung Health sync uchun vaqt beramiz
    await Future.delayed(const Duration(seconds: 5));
    _healthSteps = await _stepRepo.getTodayHealthSteps();

    if (_healthSteps >= HEALTH_SWITCH_THRESHOLD) {
      // Muvaffaqiyat — Health-only rejimga o'tamiz
      log(
        'Health now has data ($_healthSteps) — switching to HEALTH_ONLY',
        name: 'DashboardManager',
      );
      _mode = StepMode.healthOnly;
      _stepsSub?.cancel();
      _stepsSub = null;
      await StepsForegroundService.instance.stop();
      _startHealthPolling();
    } else {
      // Hali ham yo'q — gibridda qolamiz va boshqa hint ko'rsatmaymiz
      log('Health still empty — staying in hybrid', name: 'DashboardManager');
      await _ledger.setHealthHintDismissed();
      _resumeLiveTracking();
    }

    _emitCurrentSteps();
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

      if (currentSteps > _lastSyncedTodaySteps) {
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

    // Health rejimlarida tarixni ham sync qilamiz
    if (_mode == StepMode.healthOnly || _mode == StepMode.hybrid) {
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
    _hintTimer?.cancel();
    _stepsSub?.cancel();
    _forceLogoutSub?.cancel();
    return super.close();
  }
}
