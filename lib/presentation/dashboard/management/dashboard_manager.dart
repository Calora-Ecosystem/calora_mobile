import 'dart:async';
import 'dart:developer';

import 'package:calora/common/base/step_ledger_store.dart';
import 'package:calora/common/service/foreground_service.dart';
import 'package:calora/common/service/pedometer_service.dart';
import 'package:calora/common/widgets/stream/metrics_sync_bus.dart';
import 'package:calora/data/store/auth/auth_store.dart';
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

  int _lastSentTotalSteps = -1;
  int _lastMetricsRefreshedAtTotalSteps = -1;

  static const int MIN_DELTA_STEPS_TO_SEND = 20;
  static const int MIN_DELTA_STEPS_TO_REFRESH_METRICS = 20;
  static const Duration PERIODIC_SYNC_INTERVAL = Duration(minutes: 2);

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
    } catch (_) {}
  }

  Future<int> _fetchBackendTodaySteps() async {
    try {
      final list = await _stepRepo.getSteps(0);
      if (list.isEmpty) return 0;
      final v = list.first.value;
      if (v.isNaN || v.isInfinite) return 0;
      return v.floor();
    } catch (_) {
      return 0;
    }
  }

  Future<void> _startPedometerBootstrap() async {
    try {
      await _pedometerService.initialize();
      if (!_pedometerService.isInitialized) return;

      final backendToday = await _fetchBackendTodaySteps();
      final todayKey = _ledger.dayKey(DateTime.now());
      await _ledger.ensureDayAtLeast(todayKey, backendToday, minSynced: backendToday);

      final total = _ledger.totalFor(todayKey);
      final synced = _ledger.syncedFor(todayKey);

      emit(state.copyWith(todaySteps: total));
      _metricsSync.notifyUpdated(total);

      if (StepsForegroundService.instance.isRunning) {
        unawaited(StepsForegroundService.instance.syncSteps(total));
      }
      _listenToStepUpdates();
      _startPeriodicSync();
      if (total > synced) {
        await sendTodayStepsToBackend(force: true);
      } else if (total > 0) {
        await sendTodayStepsToBackend(force: true);
      }
    } catch (e) {}
  }

  void _listenToStepUpdates() {
    _stepsSub?.cancel();
    _stepsSub = _pedometerService.stepCountStream.listen(
      (sensorSteps) async {
        await _ledger.onSensorTotal(sensorSteps, DateTime.now());

        final total = _todayTotal;

        emit(state.copyWith(todaySteps: total));
        _metricsSync.notifyUpdated(total);

        if (StepsForegroundService.instance.isRunning) {
          unawaited(StepsForegroundService.instance.syncSteps(total));
        }

        if (_shouldSendToBackend(total)) {
          unawaited(sendTodayStepsToBackend());
        }
        if (_shouldRefreshMetrics(total)) {
          unawaited(_refreshMetrics(total));
        }
      },
      onError: (_) {},
    );
  }

  bool _shouldSendToBackend(int total) {
    if (total <= 0) return false;
    if (_lastSentTotalSteps < 0) return true;
    final delta = total - _lastSentTotalSteps;
    return delta >= MIN_DELTA_STEPS_TO_SEND;
  }

  bool _shouldRefreshMetrics(int total) {
    if (_lastMetricsRefreshedAtTotalSteps < 0) return true;
    final delta = total - _lastMetricsRefreshedAtTotalSteps;
    return delta >= MIN_DELTA_STEPS_TO_REFRESH_METRICS;
  }

  Future<void> sendTodayStepsToBackend({bool force = false}) async {
    final total = _todayTotal;

    if (!force && !_shouldSendToBackend(total)) return;
    if (total <= _lastSentTotalSteps && !force) return;

    await _stepRepo.sendDailyData(metric: 'Step', value: total);
    _lastSentTotalSteps = total;

    final todayKey = _ledger.dayKey(DateTime.now());
    await _ledger.setSynced(todayKey, total);

    await _refreshMetrics(total);
  }

  Future<void> _refreshMetrics(int total) async {
    if (_lastMetricsRefreshedAtTotalSteps >= 0 && total <= _lastMetricsRefreshedAtTotalSteps) {
      return;
    }
    try {
      _lastMetricsRefreshedAtTotalSteps = total;
      _metricsSync.notifyUpdated(total);
    } catch (_) {}
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(PERIODIC_SYNC_INTERVAL, (_) {
      unawaited(sendTodayStepsToBackend(force: true));
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
