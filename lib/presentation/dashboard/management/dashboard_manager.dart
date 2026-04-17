import 'dart:async';
import 'dart:developer';
import 'dart:io';

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
class DashboardManager extends Manager<DashboardState, DashboardEffect>
    with WidgetsBindingObserver {
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

  static const Duration HEALTH_SYNC_INTERVAL = Duration(seconds: 5);
  static const int MIN_DELTA_STEPS_TO_SEND = 20;

  bool _initialized = false;
  Future<void>? _initFuture;
  bool _useHealthService = false;

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
      _stepsSub?.cancel();
      _stepsSub = null;
      _syncTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      if (_useHealthService) {
        _startHealthSync();
      } else {
        _listenToStepUpdates();
      }
      unawaited(syncOfflineSteps());
    }
  }

  Future<void> _initializeInternal() async {
    try {
      _forceLogoutSub?.cancel();
      _forceLogoutSub = _authStore.onForceLogout.listen((_) async {
        _syncTimer?.cancel();
        await _stepsSub?.cancel();

        // 🌟 QO'SHILDI: Foydalanuvchi tizimdan chiqqanda bildirishnomani o'chirish
        await StepsForegroundService.instance.stop();

        publish(const DashboardEffect.forceLogout());
      });
      await _startStepCounter();
    } catch (e) {
      log('DashboardManager _initializeInternal xatosi: $e');
    }
  }

  Future<void> _startStepCounter() async {
    try {
      final bool isHealthAvailable = await _stepRepo.isHealthDataAvailable();

      if (isHealthAvailable) {
        final int initialHealthSteps = await _stepRepo.getTodayHealthSteps();
        if (initialHealthSteps == 0) {
          _useHealthService = false;
        } else {
          _useHealthService = true;
        }
      } else {
        _useHealthService = false;
      }

      if (!_useHealthService) {
        await _pedometerService.initialize();
        if (!_pedometerService.isInitialized) {
          return;
        }
      }

      final todayKey = _ledger.dayKey(DateTime.now());
      try {
        final backendSteps = await _stepRepo.getSteps(0);
        int backendTotal = 0;
        if (backendSteps.isNotEmpty) {
          backendTotal = backendSteps.first.value.toInt();
        }

        final localTotal = _ledger.totalFor(todayKey);

        if (backendTotal > localTotal) {
          await _ledger.ensureDayAtLeast(todayKey, backendTotal, minSynced: backendTotal);
          _lastSyncedTodaySteps = backendTotal;
        }
      } catch (e) {
        // xato ushlagich
      }

      await syncOfflineSteps();

      final currentTotal = _todayTotal;
      _lastSyncedTodaySteps = _ledger.syncedFor(todayKey);

      emit(state.copyWith(todaySteps: currentTotal));
      _metricsSync.notifyUpdated(currentTotal);

      // 🌟 QO'SHILDI: Foreground Service ni ishga tushirish
      if (!StepsForegroundService.instance.isRunning) {
        // TODO: Agar _authStore ichida foydalanuvchi maqsadi va vazni bo'lsa, shu yerdan oling:
        // Masalan: final userWeight = _authStore.user?.weight ?? 70.0;
        StepsForegroundService.instance.setGoalSteps(10000);
        StepsForegroundService.instance.setUserWeight(70.0);

        await StepsForegroundService.instance.start();
      }

      // Xizmat ishlayotgan bo'lsa darhol unga joriy qadamlarni jo'natamiz (bildirishnoma 0 bo'lib qolmasligi uchun)
      if (StepsForegroundService.instance.isRunning) {
        unawaited(StepsForegroundService.instance.syncSteps(currentTotal));
      }

      if (_useHealthService) {
        _startHealthSync();
      } else {
        _listenToStepUpdates();
      }
    } catch (e) {
      log('DashboardManager _startStepCounter xatosi: $e');
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

        if (lastSavedDate != todayKey) {
          if (lastSensorTotal >= 0 && sensorSteps > lastSensorTotal) {
            final finalDelta = sensorSteps - lastSensorTotal;
            await _ledger.addSteps(lastSavedDate, finalDelta);
          }
          await _ledger.setLastSensorDate(todayKey);
          await _ledger.setLastSensorTotal(sensorSteps);
          _lastSyncedTodaySteps = 0;
          unawaited(syncOfflineSteps());
          emit(state.copyWith(todaySteps: 0));
          _metricsSync.notifyUpdated(0);

          if (StepsForegroundService.instance.isRunning) {
            unawaited(StepsForegroundService.instance.syncSteps(0));
          }
          return;
        }

        await _ledger.setLastSensorTotal(sensorSteps);
        if (lastSensorTotal < 0) return;

        int delta;
        if (sensorSteps < lastSensorTotal) {
          delta = sensorSteps;
        } else {
          delta = sensorSteps - lastSensorTotal;
        }

        if (delta <= 0) return;

        await _ledger.addSteps(todayKey, delta);
        final newTotal = _ledger.totalFor(todayKey);
        emit(state.copyWith(todaySteps: newTotal));

        if (StepsForegroundService.instance.isRunning) {
          unawaited(StepsForegroundService.instance.syncSteps(newTotal));
        }

        if (_shouldSyncToday(newTotal)) {
          unawaited(_syncTodaySteps(force: true));
        }
      },
      onError: (e) {
        log('Pedometer stream xatosi: $e');
      },
    );
  }

  void _startHealthSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(HEALTH_SYNC_INTERVAL, (_) {
      unawaited(_syncTodaySteps());
    });
  }

  bool _shouldSyncToday(int total) {
    if (total <= 0) return false;
    final delta = total - _lastSyncedTodaySteps;
    return delta >= MIN_DELTA_STEPS_TO_SEND;
  }

  Future<void> _syncTodaySteps({bool force = false}) async {
    if (_isSyncingToday && !force) return;

    _isSyncingToday = true;

    try {
      int currentSteps;
      if (_useHealthService) {
        currentSteps = await _stepRepo.getTodayHealthSteps();
      } else {
        currentSteps = _todayTotal;
      }

      if (currentSteps > _lastSyncedTodaySteps) {
        final todayKey = _ledger.dayKey(DateTime.now());
        await _stepRepo.sendDailyData(metric: 'Step', value: currentSteps);
        await _ledger.setSynced(todayKey, currentSteps);
        _lastSyncedTodaySteps = currentSteps;
        emit(state.copyWith(todaySteps: currentSteps));
        _metricsSync.notifyUpdated(currentSteps);

        if (StepsForegroundService.instance.isRunning) {
          unawaited(StepsForegroundService.instance.syncSteps(currentSteps));
        }
      }
    } catch (e) {
      //
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
        //
      }
    }

    if (_useHealthService) {
      final datePeriod = _stepRepo.getDatePeriods(2, 0);
      await _stepRepo.sendHealthData(from: datePeriod['from']!, to: datePeriod['to']!);
    }

    await _syncTodaySteps(force: true);
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
