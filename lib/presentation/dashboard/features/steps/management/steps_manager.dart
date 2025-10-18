import 'dart:async';
import 'dart:developer';

import 'package:calora/domain/model/norms/norms.dart';
import 'package:calora/domain/repo/step/step_repo.dart';
import 'package:calora/presentation/dashboard/features/steps/management/steps_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class StepsManager extends Manager<StepsState, StepsEffect> {
  final StepRepo stepRepo;
  Timer? _timer;

  StepsManager(this.stepRepo) : super(StepsState());

  void updateTodaySteps(int steps) {
    emit(state.copyWith(stepCount: steps));
  }

  void start() {
    _timer = Timer.periodic(const Duration(hours: 1), (_) {
      sendDailyData();
    });

    sendDailyData();
  }

  Future<void> getSteps() async {
    await stepRepo
        .getSteps(state.period, offset: state.offset)
        .handle(
          onStart: () => emit(state.copyWith(isLoading: true)),
          onData: (data) => emit(state.copyWith(steps: data, isLoading: false)),
          onDone: () => emit(state.copyWith(isLoading: false)),
          onError: (_) => emit(state.copyWith(isLoading: false)),
        );
  }

  Future<void> getStats(int value) async {
    log("ResultStepManageStatsCalled->$value");
    await stepRepo
        .getStats(state.period, offset: state.offset)
        .handle(
          onStart: () => emit(state.copyWith(isLoading: true)),
          onData: (data) =>
              emit(state.copyWith(userStates: data, isLoading: false)),
          onDone: () => emit(state.copyWith(isLoading: false)),
          onError: (_) => emit(state.copyWith(isLoading: false)),
        );
  }

  Future<void> getUserMetrics() async {
    await stepRepo.getUserMetrics().handle(
      onStart: () => emit(state.copyWith(isLoading: true)),
      onData: (data) => emit(state.copyWith(metrics: data, isLoading: false)),
      onDone: () => emit(state.copyWith(isLoading: false)),
      onError: (_) => emit(state.copyWith(isLoading: false)),
    );
  }

  Future<void> getNorms() async {
    await stepRepo.getNorms().handle(
      onStart: () => emit(state.copyWith(isLoading: true)),
      onData: (data) => emit(state.copyWith(norms: data, isLoading: false)),
      onDone: () => emit(state.copyWith(isLoading: false)),
      onError: (_) => emit(state.copyWith(isLoading: false)),
    );
  }

  Future<void> updateNorm(NormsRequest norm) async {
    await stepRepo
        .updateNorm(norm)
        .handle(
          onStart: () => emit(state.copyWith(isLoading: true)),
          onData: (_) => getNorms(),
          onDone: () => emit(state.copyWith(isLoading: false)),
          onError: (_) => emit(state.copyWith(isLoading: false)),
        );
  }

  Future<void> deleteNorm(String metric) async {
    await stepRepo
        .deleteNorm(metric)
        .handle(
          onStart: () => emit(state.copyWith(isLoading: true)),
          onData: (_) => getNorms(),
          onDone: () => emit(state.copyWith(isLoading: false)),
          onError: (_) => emit(state.copyWith(isLoading: false)),
        );
  }

  Future<void> sendDailyData() async {
    await stepRepo
        .sendDailyData(metric: "Step", value: state.stepCount)
        .handle(
          onStart: () => emit(state),
          onData: (_) => emit(state),
          onDone: () => emit(state),
          onError: (_) => emit(state),
        );
  }

  void changePeriod(int newPeriod) {
    emit(state.copyWith(period: newPeriod, offset: 0));
    getSteps();
    getStats(1);
  }

  void changeOffset(int change) {
    emit(state.copyWith(offset: state.offset + change));
    getSteps();
    getStats(2);
  }
}
