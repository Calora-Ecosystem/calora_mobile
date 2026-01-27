import 'dart:async';
import 'dart:developer';

import 'package:calora/common/service/pedometer_service.dart';
import 'package:calora/domain/model/dailies/steps_stat.dart';
import 'package:calora/domain/repo/step/step_repo.dart';
import 'package:calora/presentation/dashboard/management/dashboard_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class DashboardManager extends Manager<DashboardState, DashboardEffect> {
  final StepRepo _stepRepo;
  final PedometerService _pedometerService;

  Timer? _syncTimer;
  StreamSubscription<int>? _stepsSub;

  DashboardManager(this._stepRepo, this._pedometerService) : super(const DashboardState());

  @override
  void initialize() async {
    super.initialize();
    await _startPedometer();
  }

  Future<void> _startPedometer() async {
    try {
      final hasPermission = await _pedometerService.ensurePermissionGranted();
      if (!hasPermission) {
        log('DashboardManager: Permission denied');
        return;
      }

      await _pedometerService.initializePedometer();

      await _syncWithBackend();

      _listenToStepUpdates();

      _startPeriodicSync();

      log('DashboardManager: Pedometer started successfully');
    } catch (e, s) {
      log('DashboardManager: Failed to start pedometer: $e', error: e, stackTrace: s);
    }
  }

  void _listenToStepUpdates() {
    _stepsSub?.cancel();
    _stepsSub = _pedometerService.todayStepsStream.listen((steps) {
      log('📊 Real-time steps: $steps');
      emit(state.copyWith(todaySteps: steps));
    });
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      log('⏰ Periodic sync triggered');
      sendTodayStepsToBackend();
    });

    // Initial send
    sendTodayStepsToBackend();
  }

  Future<void> sendTodayStepsToBackend() async {
    try {
      final steps = _pedometerService.dailySteps;
      log('📤 Sending steps to backend: $steps');

      await _stepRepo
          .sendDailyData(metric: 'Step', value: steps)
          .handle(
            onStart: () {},
            onData: (_) => log('✅ Steps sent successfully: $steps'),
            onDone: () {},
            onError: (e) => log('❌ Failed to send steps: $e'),
          );
    } catch (e, s) {
      log('Error sending steps to backend: $e', error: e, stackTrace: s);
    }
  }

  Future<void> _syncWithBackend() async {
    try {
      await _stepRepo
          .getSteps(0)
          .handle(
            onStart: () {},
            onData: (data) async {
              if (data.isNotEmpty) {
                await _getRangeSteps(data.first.date, DateTime.now());
              } else {
                await sendTodayStepsToBackend();
              }
            },
            onDone: () {},
            onError: (e) => log('Error getting steps from backend: $e'),
          );
    } catch (e, s) {
      log('Error syncing with backend: $e', error: e, stackTrace: s);
    }
  }

  Future<void> _getRangeSteps(DateTime fromDate, DateTime toDate) async {
    try {
      final result = await _pedometerService.getDailyStepsForRange(
        fromDate,
        toDate,
      );
      final steps = result.entries
          .map(
            (e) => StepsWithMetricsRequest(
              date: e.key,
              value: e.value.toDouble(),
            ),
          )
          .toList();

      for (final e in result.entries) {
        log("📅 ${e.key.toIso8601String().split('T')[0]}: ${e.value} steps");
      }

      await _sendStepsDataDateRange(steps);
    } catch (e, s) {
      log('DashboardManager _getRangeSteps error: $e', error: e, stackTrace: s);
    }
  }

  Future<void> _sendStepsDataDateRange(
    List<StepsWithMetricsRequest> steps,
  ) async {
    await _stepRepo
        .sendStepDataDateRange(steps: steps)
        .handle(
          onStart: () {},
          onData: (_) => log('✅ Range steps sent successfully'),
          onDone: () {},
          onError: (e) => log('❌ Failed to send range steps: $e'),
        );
  }

  @override
  Future<void> close() {
    _syncTimer?.cancel();
    _stepsSub?.cancel();
    return super.close();
  }
}
