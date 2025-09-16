import 'package:calora/domain/model/norms/norms.dart';
import 'package:calora/domain/repo/step/step_repo.dart';
import 'package:calora/presentation/dashboard/features/steps/management/steps_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class StepsManager extends Manager<StepsState, StepsEffect> {
  final StepRepo stepRepo;

  StepsManager(this.stepRepo) : super(StepsState());

  void updateTodaySteps(int steps) async {
    emit(state.copyWith(stepCount: steps));
  }

  void getSteps(int period, {int offset = 0}) async {
    await stepRepo
        .getSteps(period, offset: offset)
        .handle(
          onStart: () => emit(state.copyWith(isLoading: true)),
          onData: (data) {
            emit(state.copyWith(steps: data));
          },
          onDone: () => emit(state.copyWith(isLoading: false)),
          onError: (error) => emit(state.copyWith(isLoading: false)),
        );
  }

  void getUserMetrics() async {
    await stepRepo.getUserMetrics().handle(
      onStart: () => emit(state.copyWith(isLoading: true)),
      onData: (data) {
        emit(state.copyWith(metrics: data));
      },
      onDone: () => emit(state.copyWith(isLoading: false)),
      onError: (error) => emit(state.copyWith(isLoading: false)),
    );
  }

  void getStats(int period, {int offset = 0}) async {
    await stepRepo
        .getStats(period, offset: offset)
        .handle(
          onStart: () => emit(state),
          onData: (data) {
            emit(state.copyWith(userStates: data));
          },
          onDone: () => emit(state),
          onError: (error) => emit(state),
        );
  }

  void getNorms() async {
    await stepRepo.getNorms().handle(
      onStart: () => emit(state.copyWith(isLoading: true)),
      onData: (data) => emit(state.copyWith(norms: data, isLoading: false)),
      onDone: () => emit(state.copyWith(isLoading: false)),
      onError: (error) => emit(state.copyWith(isLoading: false)),
    );
  }

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
