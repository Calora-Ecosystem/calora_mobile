import 'package:calora/domain/repo/step/step_repo.dart';
import 'package:calora/presentation/dashboard/features/steps/management/steps_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class StepsManager extends Manager<StepsState, StepsEffect> {
  final StepRepo stepRepo;

  StepsManager(this.stepRepo) : super(const StepsState());

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
