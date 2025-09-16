import 'dart:developer';

import 'package:calora/domain/model/norms/norms.dart';
import 'package:calora/domain/repo/step/step_repo.dart';
import 'package:calora/presentation/dashboard/features/steps/management/steps_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class StepsManager extends Manager<StepsState, StepsEffect> {
  final StepRepo stepRepo;

  StepsManager(this.stepRepo) : super(StepsState());

  /// Stepsni olish (daily/weekly/monthly)
  void getSteps(int period, {int offset = 0}) async {
    await stepRepo
        .getSteps(period, offset: offset)
        .handle(
          onStart: () => emit(state.copyWith(isLoading: true)),
          onData: (data) {
            log('Steps data:::: $data');
            emit(state.copyWith(steps: data));
          },
          onDone: () => emit(state.copyWith(isLoading: false)),
          onError: (error) => emit(state.copyWith(isLoading: false)),
        );
  }

  /// Foydalanuvchi metricslarini olish
  void getUserMetrics() async {
    await stepRepo.getUserMetrics().handle(
      onStart: () => emit(state.copyWith(isLoading: true)),
      onData: (data) {
        log('Metrics data:::: $data');
        emit(state.copyWith(metrics: data));
      },
      onDone: () => emit(state.copyWith(isLoading: false)),
      onError: (error) => emit(state.copyWith(isLoading: false)),
    );
  }

  /// Steps statistikasini olish (leaderboard)
  void getStats(int period, {int offset = 0}) async {
    await stepRepo
        .getStats(period, offset: offset)
        .handle(
          onStart: () => emit(state),
          onData: (data) {
            log('Stats data:::: $data');
            emit(state.copyWith(userStates: data));
          },
          onDone: () => emit(state),
          onError: (error) => emit(state),
        );
  }

  /// Normslarni olish
  void getNorms() async {
    await stepRepo.getNorms().handle(
      onStart: () => emit(state.copyWith(isLoading: true)),
      onData: (data) => emit(state.copyWith(norms: data, isLoading: false)),
      onDone: () => emit(state.copyWith(isLoading: false)),
      onError: (error) => emit(state.copyWith(isLoading: false)),
    );
  }

  /// Normni yangilash
  void update(Norms norm) async {
    await stepRepo
        .updateNorm(norm)
        .handle(
          onStart: () => emit(state.copyWith(isLoading: true)),
          onData: (data) {},
          onDone: () => emit(state.copyWith(isLoading: false)),
          onError: (error) => emit(state.copyWith(isLoading: false)),
        );
  }

  /// Normni o'chirish (kerak bo'lsa)
  void deleteNorm(String metric) async {
    await stepRepo
        .deleteNorm(metric)
        .handle(
          onStart: () => emit(state.copyWith(isLoading: true)),
          onData: (data) {},
          onDone: () => emit(state.copyWith(isLoading: false)),
          onError: (error) => emit(state.copyWith(isLoading: false)),
        );
  }
}
