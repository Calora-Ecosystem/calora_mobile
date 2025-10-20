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

  // todo will be fix int the future
  late PedometerService _pedometerService;

  DashboardManager(this._stepRepo) : super(const DashboardState());

  @override
  void initialize() async {
    super.initialize();
    _initializePedometerService();
    await getSteps();
  }

  Future<void> getSteps() async {
    await _stepRepo
        .getSteps(0, offset: 0, isSortDate: true)
        .handle(
          onStart: () => {},
          onData: (data) => {
            if (data.isNotEmpty)
              _getRangeSteps(data.first.date, DateTime.now())
            else
              sendDailyData(),
          },
          onDone: () => {},
          onError: (_) => {},
        );
  }

  void _initializePedometerService() async {
    _pedometerService = PedometerService(
      onTodayStepCountUpdated: (todaySteps) {},
      onError: (error) {
      },
    );
    await _pedometerService.initializePedometer();
  }

  void _getRangeSteps(DateTime fromDate, DateTime toDate) async {
    final toDate = DateTime.now();
    Map<DateTime, int> result = await _pedometerService.getDailyStepsForRange(
      fromDate,
      toDate,
    );
    List<StepsWithMetricsRequest> steps = [];
    for (var entry in result.entries) {
      steps.add(
        StepsWithMetricsRequest(
          date: entry.key,
          metric: "Step",
          value: entry.value.toDouble(),
        ),
      );
      log(
        "Results: ${entry.key.toIso8601String().split('T')[0]}: ${entry.value}",
      );
    }
    _sendStepsDataDateRange(steps);
  }

  void _sendStepsDataDateRange(List<StepsWithMetricsRequest> steps) async {
    await _stepRepo
        .sendStepDataDateRange(steps: steps)
        .handle(
          onStart: () => {},
          onData: (_) => {},
          onDone: () => {},
          onError: (_) => {},
        );
  }

  void sendDailyData() async {
    int todayCounts = await _pedometerService.getTodaySteps();
    await _stepRepo
        .sendDailyData(metric: "Step", value: todayCounts)
        .handle(
          onStart: () => emit(state),
          onData: (_) => emit(state),
          onDone: () => emit(state),
          onError: (_) => emit(state),
        );
  }
}
