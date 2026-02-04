import 'dart:async';
import 'dart:developer';

import 'package:calora/common/service/foreground_service.dart';
import 'package:calora/common/service/pedometer_service.dart';
import 'package:calora/common/widgets/stream/metrics_sync_bus.dart';
import 'package:calora/domain/repo/step/step_repo.dart';
import 'package:calora/presentation/dashboard/management/dashboard_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class DashboardManager extends Manager<DashboardState, DashboardEffect> {
  final StepRepo _stepRepo;
  final PedometerService _pedometerService;
  final MetricsSyncService _metricsSync;

  StreamSubscription<int>? _stepsSub;
  Timer? _syncTimer;

  int _latestDeviceSteps = 0;

  int _backendBaseSteps = 0;

  int _deviceStartSteps = 0;

  int _lastSentTotalSteps = -1;
  int _lastMetricsRefreshedAtTotalSteps = -1;

  static const int MIN_DELTA_STEPS_TO_SEND = 20;
  static const int MIN_DELTA_STEPS_TO_REFRESH_METRICS = 20;
  static const Duration PERIODIC_SYNC_INTERVAL = Duration(minutes: 2);

  DashboardManager(
    this._stepRepo,
    this._pedometerService,
    this._metricsSync,
  ) : super(const DashboardState());

  int get _totalSteps {
    final delta = _latestDeviceSteps - _deviceStartSteps;
    final safeDelta = delta < 0 ? 0 : delta;
    return _backendBaseSteps + safeDelta;
  }

  @override
  void initialize() async {
    super.initialize();
    await _startPedometer();
  }

  Future<int> _fetchBackendTodaySteps() async {
    try {
      final list = await _stepRepo.getSteps(0);
      if (list.isEmpty) return 0;

      final v = list.first.value;
      if (v.isNaN || v.isInfinite) return 0;

      return v.floor();
    } catch (e) {
      log('Backend today steps (getSteps) olish xatosi: $e', name: 'DashboardManager');
      return 0;
    }
  }

  Future<void> _startPedometer() async {
    try {
      final hasPermission = await _pedometerService.ensurePermissionGranted();
      if (!hasPermission) {
        log('Pedometer ruxsati rad etildi', name: 'DashboardManager');
        return;
      }

      await _pedometerService.initializePedometer();

      _latestDeviceSteps = _pedometerService.dailySteps;

      final backendToday = await _fetchBackendTodaySteps();

      _backendBaseSteps = backendToday < _latestDeviceSteps ? _latestDeviceSteps : backendToday;

      _deviceStartSteps = _latestDeviceSteps;

      final total = _totalSteps;
      emit(state.copyWith(todaySteps: total));
      if (StepsForegroundService.instance.isRunning) {
        unawaited(StepsForegroundService.instance.syncSteps(_totalSteps));
      }
      await sendTodayStepsToBackend(force: true);

      _listenToStepUpdates();
      _startPeriodicSync();

      log(
        'Bootstrap done: backendToday=$backendToday, base=$_backendBaseSteps, deviceStart=$_deviceStartSteps, total=$total',
        name: 'DashboardManager',
      );
    } catch (e, s) {
      log(
        'Pedometer ishga tushmadi: $e',
        name: 'DashboardManager',
        error: e,
        stackTrace: s,
      );
    }
  }

  void _listenToStepUpdates() {
    _stepsSub?.cancel();
    _stepsSub = _pedometerService.todayStepsStream.listen(
      (deviceSteps) {
        _latestDeviceSteps = deviceSteps;
        final total = _totalSteps;
        emit(state.copyWith(todaySteps: total));
        _metricsSync.notifyUpdated(total);
        if (_shouldSendToBackend(total)) {
          unawaited(sendTodayStepsToBackend());
        }
        if (_shouldRefreshMetrics(total)) {
          unawaited(_refreshMetrics(total));
        }
      },
      onError: (e) {
        log('Steps stream xatosi: $e', name: 'DashboardManager');
      },
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

    if (total <= 0) {
      log('Skip sending steps: total=$total (force: $force)', name: 'DashboardManager');
      return;
    }

    if (_lastSentTotalSteps >= 0 && total <= _lastSentTotalSteps) return;

    if (!force) {
      if (_lastSentTotalSteps >= 0) {
        final delta = total - _lastSentTotalSteps;
        if (delta < MIN_DELTA_STEPS_TO_SEND) return;
      }
    }

    try {
      await _stepRepo.sendDailyData(metric: 'Step', value: total);

      _lastSentTotalSteps = total;
      log('TOTAL qadamlar backendga yuborildi: $total (force: $force)', name: 'DashboardManager');

      await _refreshMetrics(total);
    } catch (e, s) {
      log('Qadam yuborish xatosi: $e', name: 'DashboardManager', stackTrace: s);
    }
  }

  Future<void> _refreshMetrics(int total) async {
    if (_lastMetricsRefreshedAtTotalSteps >= 0 && total <= _lastMetricsRefreshedAtTotalSteps) return;

    try {
      _lastMetricsRefreshedAtTotalSteps = total;

      _metricsSync.notifyUpdated(total);
      log('Metrikalar yangilandi — TOTAL qadamlar: $total', name: 'DashboardManager');
    } catch (e, s) {
      log('Metrikalarni yangilashda xato: $e', name: 'DashboardManager', stackTrace: s);
    }
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
    return super.close();
  }
}
