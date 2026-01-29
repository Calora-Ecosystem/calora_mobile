import 'dart:async';
import 'dart:developer';

import 'package:calora/common/service/pedometer_service.dart';
import 'package:calora/common/widgets/stream/metrics_sync_bus.dart';
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

  StreamSubscription<int>? _stepsSub;
  Timer? _syncTimer;

  int _latestSteps = 0;
  int _lastSentSteps = -1;
  int _lastMetricsRefreshedAtSteps = -1;

  static const int MIN_DELTA_STEPS_TO_SEND = 30;
  static const int MIN_DELTA_STEPS_TO_REFRESH_METRICS = 25;
  static const Duration PERIODIC_SYNC_INTERVAL = Duration(minutes: 2);

  DashboardManager(
    this._stepRepo,
    this._pedometerService,
    this._metricsSync,
  ) : super(const DashboardState());

  @override
  void initialize() async {
    super.initialize();
    await _startPedometer();
    await sendTodayStepsToBackend(force: true);
  }

  Future<void> _startPedometer() async {
    try {
      final hasPermission = await _pedometerService.ensurePermissionGranted();
      if (!hasPermission) {
        log('Pedometer ruxsati rad etildi', name: 'DashboardManager');
        return;
      }

      await _pedometerService.initializePedometer();

      _latestSteps = _pedometerService.dailySteps;
      emit(state.copyWith(todaySteps: _latestSteps));

      await sendTodayStepsToBackend(force: true);

      _listenToStepUpdates();
      _startPeriodicSync();

      log('Pedometer muvaffaqiyatli ishga tushdi', name: 'DashboardManager');
    } catch (e, s) {
      log('Pedometer ishga tushmadi: $e', name: 'DashboardManager', error: e, stackTrace: s);
    }
  }

  void _listenToStepUpdates() {
    _stepsSub?.cancel();
    _stepsSub = _pedometerService.todayStepsStream.listen(
      (steps) {
        _latestSteps = steps;
        emit(state.copyWith(todaySteps: steps));

        if (_shouldSendToBackend(steps)) {
          sendTodayStepsToBackend();
        }

        if (_shouldRefreshMetrics(steps)) {
          _refreshMetrics();
        }
      },
      onError: (e) {
        log('Steps stream xatosi: $e', name: 'DashboardManager');
      },
    );
  }

  bool _shouldSendToBackend(int current) {
    if (_lastSentSteps < 0) return true;
    final delta = current - _lastSentSteps;
    return delta >= MIN_DELTA_STEPS_TO_SEND;
  }

  bool _shouldRefreshMetrics(int current) {
    if (_lastMetricsRefreshedAtSteps < 0) return true;
    final delta = current - _lastMetricsRefreshedAtSteps;
    return delta >= MIN_DELTA_STEPS_TO_REFRESH_METRICS;
  }

  Future<void> sendTodayStepsToBackend({bool force = false}) async {
    final currentSteps = _latestSteps;

    if (!force) {
      if (_lastSentSteps >= 0) {
        final delta = currentSteps - _lastSentSteps;
        if (delta < MIN_DELTA_STEPS_TO_SEND) {
          return;
        }
      }
    }
    try {
      await _stepRepo.sendDailyData(metric: 'Step', value: currentSteps);
      _lastSentSteps = currentSteps;
      log('Qadamlar backendga yuborildi: $currentSteps (force: $force)', name: 'DashboardManager');
      _refreshMetrics();
    } catch (e) {
      log('Qadam yuborish xatosi: $e', name: 'DashboardManager');
    }
  }

  Future<void> _refreshMetrics() async {
    if (_latestSteps <= _lastMetricsRefreshedAtSteps) return;

    try {
      _lastMetricsRefreshedAtSteps = _latestSteps;

      _metricsSync.notifyUpdated(_latestSteps);

      log('Metrikalar yangilandi — qadamlar: $_latestSteps', name: 'DashboardManager');
    } catch (e) {
      log('Metrikalarni yangilashda xato: $e', name: 'DashboardManager');
    }
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();

    _syncTimer = Timer.periodic(PERIODIC_SYNC_INTERVAL, (_) {
      sendTodayStepsToBackend(force: true);
    });

    sendTodayStepsToBackend(force: true);
  }

  @override
  Future<void> close() {
    _syncTimer?.cancel();
    _stepsSub?.cancel();
    return super.close();
  }
}
