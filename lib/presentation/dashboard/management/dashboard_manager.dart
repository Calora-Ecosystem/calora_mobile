import 'dart:async';

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

  StreamSubscription<int>? _stepsSub;
  Timer? _syncTimer;

  StreamSubscription<void>? _forceLogoutSub;

  int _backendBaseSteps = 0;
  int? _sensorBaseSteps;
  int _latestSensorSteps = 0;
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

  int get _totalSteps {
    if (_sensorBaseSteps == null) {
      return _backendBaseSteps;
    }
    final delta = _latestSensorSteps - _sensorBaseSteps!;
    final safeDelta = delta < 0 ? 0 : delta;
    final total = _backendBaseSteps + safeDelta;
    return total < 0 ? 0 : total;
  }

  @override
  void initialize() {
    super.initialize();
    if (_initialized) {
      return;
    }
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
    } catch (e, s) {}
  }

  Future<int> _fetchBackendTodaySteps() async {
    try {
      final list = await _stepRepo.getSteps(0);
      if (list.isEmpty) {
        return 0;
      }
      final v = list.first.value;
      if (v.isNaN || v.isInfinite) {
        return 0;
      }
      final steps = v.floor();
      return steps;
    } catch (e, s) {
      return 0;
    }
  }

  Future<void> _startPedometerBootstrap() async {
    try {
      await _pedometerService.initialize();

      if (!_pedometerService.isInitialized) {
        return;
      }
      final backendToday = await _fetchBackendTodaySteps();
      _backendBaseSteps = backendToday;

      emit(state.copyWith(todaySteps: _totalSteps));
      _metricsSync.notifyUpdated(_totalSteps);
      if (StepsForegroundService.instance.isRunning) {
        unawaited(StepsForegroundService.instance.syncSteps(_totalSteps));
      }
      await sendTodayStepsToBackend(force: true);
      _listenToStepUpdates();

      _startPeriodicSync();
    } catch (e, s) {}
  }

  void _listenToStepUpdates() {
    _stepsSub?.cancel();

    _stepsSub = _pedometerService.stepCountStream.listen(
      (sensorSteps) {
        if (_sensorBaseSteps == null) {
          _sensorBaseSteps = sensorSteps;
        }

        _latestSensorSteps = sensorSteps;
        final total = _totalSteps;

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
      onError: (e) {},
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
    final total = _totalSteps;
    if (!force && !_shouldSendToBackend(total)) {
      return;
    }
    if (total <= _lastSentTotalSteps && !force) {
      return;
    }
    try {
      await _stepRepo.sendDailyData(metric: 'Step', value: total);
      _lastSentTotalSteps = total;
      await _refreshMetrics(total);
    } catch (e, s) {}
  }

  Future<void> _refreshMetrics(int total) async {
    if (_lastMetricsRefreshedAtTotalSteps >= 0 && total <= _lastMetricsRefreshedAtTotalSteps) {
      return;
    }
    try {
      _lastMetricsRefreshedAtTotalSteps = total;
      _metricsSync.notifyUpdated(total);
    } catch (e, s) {}
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
