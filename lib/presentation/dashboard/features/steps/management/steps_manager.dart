import 'dart:developer';

import 'package:calora/domain/repo/step/step_repo.dart';
import 'package:calora/presentation/dashboard/features/steps/management/steps_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class StepsManager extends Manager<StepsState, StepsEffect> {
  final StepRepo stepRepo;

  StepsManager(this.stepRepo) : super(const StepsState());

  void updateTodaySteps(int steps) async{
    emit(state.copyWith(stepCount: steps));
  }

  void getSteps() async {
    await stepRepo.getSteps().handle(
      onStart: () {},
      onData: (data) {
        // emit(state.copyWith(stepCount: data));
      },
      onDone: () {},
      onError: (error) {},
    );
  }

  void getUserMetrics() async {
    await stepRepo.getUserMetrics().handle(
      onStart: () {},
      onData: (data) {
        emit(state.copyWith(metrics: data));
      },
      onDone: () {},
      onError: (error) {},
    );
  }

  void getStats() async {
    await stepRepo.getStats().handle(
      onStart: () {},
      onData: (data) {
        emit(state.copyWith(statsTotal: data));
      },
      onDone: () {},
      onError: (error) {},
    );
  }

  void fetchUserStates() async {
    await stepRepo.fetchUserStates().handle(
      onStart: () {},
      onData: (data) {
        emit(state.copyWith(userStates: data));
      },
      onDone: () {},
      onError: (error) {},
    );
  }
}
