import 'package:calora/common/base/profile_store.dart';
import 'package:calora/domain/model/norms/norms.dart';
import 'package:calora/domain/repo/profile/profile_repo.dart';
import 'package:calora/domain/repo/step/step_repo.dart';
import 'package:calora/presentation/dashboard/features/home/management/home_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';
import 'package:permission_handler/permission_handler.dart';

@injectable
class HomeManager extends Manager<HomeState, HomeEffect> {
  final ProfileRepo _profileRepo;
  final StepRepo _stepRepo;

  HomeManager(this._profileRepo, this._stepRepo) : super(HomeState());

  void getUserInfo() {
    _profileRepo.getProfile().handle(
      onStart: () => emit(state.copyWith(isLoading: true)),
      onData: (profile) {
        emit(state.copyWith(profile: profile, isLoading: false));
        profileStore.clear();
        profileStore.set(profile);
      },
      onError: (error) => emit(state.copyWith(isLoading: false)),
    );
  }

  Future<void> requestPedometerPermissions() async {
    await [Permission.activityRecognition, Permission.sensors, Permission.locationWhenInUse].request();
  }

  void updateTodaySteps(int steps) {
    emit(state.copyWith(currentSteps: steps));
  }

  void updateWaterIntake(double liters) {
    emit(state.copyWith(waterIntake: liters));
  }

  void getStepNorm() {
    _stepRepo.getNorms().handle(
      onStart: () => emit(state.copyWith(isLoading: true)),
      onData: (data) {
        final stepValue = data
            .firstWhere((e) => e.metric == "Step", orElse: () => NormsRequest(metric: "Step", value: 0))
            .value;
        final waterValue = data
            .firstWhere((e) => e.metric == "Water", orElse: () => NormsRequest(metric: "Water", value: 0))
            .value;
        final kcalValue = data
            .firstWhere((e) => e.metric == "Kcal", orElse: () => NormsRequest(metric: "Kcal", value: 0))
            .value;

        emit(
          state.copyWith(
            norms: data,
            isLoading: false,
            targetSteps: stepValue.toInt(),
            targetLiters: waterValue,
            targetKcal: kcalValue,
          ),
        );
      },
      onError: (error) => emit(state.copyWith(isLoading: false)),
    );
  }
}
