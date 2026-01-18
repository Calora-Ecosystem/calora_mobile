import 'package:calora/common/base/profile_store.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/domain/model/dailies/dailies_request.dart';
import 'package:calora/domain/model/norms/norms.dart';
import 'package:calora/domain/model/nutrient/nutrient_data.dart';
import 'package:calora/domain/model/summary/summary_request.dart';
import 'package:calora/domain/repo/home/home_repo.dart';
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
  final HomeRepo _homeRepo;

  HomeManager(this._profileRepo, this._stepRepo, this._homeRepo)
    : super(HomeState());

  Future<void> getUserInfo() async => await _profileRepo.getProfile().handle(
    onStart: () => emit(state.copyWith(isLoading: true)),
    onError: (error) => emit(state.copyWith(isLoading: false)),
    onData: (profile) {
      emit(state.copyWith(profile: profile, isLoading: false));
      profileStore.clear();
      profileStore.set(profile);
    },
  );

  Future<void> requestPedometerPermissions() async {
    await [
      Permission.activityRecognition,
      Permission.sensors,
      Permission.locationWhenInUse,
    ].request();
  }

  void updateDay(DateTime day) {
    emit(state.copyWith(day: day));
  }

  void updateTodaySteps(int steps) {
    emit(state.copyWith(currentSteps: steps));
  }

  void updateWaterIntake(double liters) {
    emit(state.copyWith(waterIntake: liters));
  }

  void postWater() {
    _homeRepo.postWater(
      DailiesRequest(
        metric: 'Water',
        value: state.waterIntake,
        date: DateTime.now().toIso8601String(),
      ),
    );
  }

  void getDailyStep() {
    _homeRepo
        .getDailiesSteps(state.day ?? DateTime.now())
        .handle(
          onStart: () => emit(state.copyWith(isMetricsLoading: true)),
          onData: (data) {
            emit(
              state.copyWith(
                currentSteps: data.value.toInt(),
                isMetricsLoading: false,
              ),
            );
          },
          onError: (error) => emit(state.copyWith(isMetricsLoading: false)),
        );
  }

  void getWater() {
    _homeRepo
        .getDailiesWater(state.day ?? DateTime.now())
        .handle(
          onStart: () => emit(state.copyWith(isWaterLoading: true)),
          onData: (data) {
            emit(
              state.copyWith(waterIntake: data.value, isWaterLoading: false),
            );
          },
          onError: (error) => emit(state.copyWith(isWaterLoading: false)),
        );
  }

  void getSummary() {
    _homeRepo
        .getSummary(state.day ?? DateTime.now())
        .handle(
          onStart: () => emit(state.copyWith(isSummaryLoading: true)),
          onData: (data) {
            emit(state.copyWith(summary: data, isSummaryLoading: false));
            updateNutrientsPercent(data);
          },
          onError: (error) => emit(state.copyWith(isSummaryLoading: false)),
        );
  }

  void getMetrics() {
    _homeRepo
        .getMetrics(state.day ?? DateTime.now())
        .handle(
          onStart: () => emit(state.copyWith(isMetricsLoading: true)),
          onData: (data) {
            emit(state.copyWith(metrics: data, isMetricsLoading: false));
          },
          onError: (error) => emit(state.copyWith(isMetricsLoading: false)),
        );
  }

  void getStepNorm() {
    _stepRepo.getNorms().handle(
      onStart: () => emit(state.copyWith(isLoading: true)),
      onData: (data) {
        final stepValue = data
            .firstWhere(
              (e) => e.metric == 'Step',
              orElse: () => NormsRequest(metric: 'Step', value: 0),
            )
            .value;
        final waterValue = data
            .firstWhere(
              (e) => e.metric == 'Water',
              orElse: () => NormsRequest(metric: 'Water', value: 0),
            )
            .value;
        final kcalValue = data
            .firstWhere(
              (e) => e.metric == 'Kcal',
              orElse: () => NormsRequest(metric: 'Kcal', value: 0),
            )
            .value;
        final proteinValue = data
            .firstWhere(
              (e) => e.metric == 'Protein',
              orElse: () => NormsRequest(metric: 'Protein', value: 0),
            )
            .value;
        final fatValue = data
            .firstWhere(
              (e) => e.metric == 'Fat',
              orElse: () => NormsRequest(metric: 'Fat', value: 0),
            )
            .value;
        final carbsValue = data
            .firstWhere(
              (e) => e.metric == 'Carb',
              orElse: () => NormsRequest(metric: 'Carb', value: 0),
            )
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

  void updateNutrientsPercent(SummaryRequest summary) {
    final proteinNorm = state.norms
        .firstWhere(
          (e) => e.metric == 'Protein',
          orElse: () => NormsRequest(metric: 'Protein', value: 1),
        )
        .value;
    final fatNorm = state.norms
        .firstWhere(
          (e) => e.metric == 'Fat',
          orElse: () => NormsRequest(metric: 'Fat', value: 1),
        )
        .value;
    final carbNorm = state.norms
        .firstWhere(
          (e) => e.metric == 'Carb',
          orElse: () => NormsRequest(metric: 'Carb', value: 1),
        )
        .value;

    emit(
      state.copyWith(
        nutrients: [
          NutrientInfo(
            name: Strings.proteins,
            value: summary.sum.Protein,
            percent: proteinNorm > 0
                ? (summary.sum.Protein / proteinNorm).clamp(0.0, 1.0)
                : 0,
          ),
          NutrientInfo(
            name: Strings.oils,
            value: summary.sum.Fat,
            percent: fatNorm > 0
                ? (summary.sum.Fat / fatNorm).clamp(0.0, 1.0)
                : 0,
          ),
          NutrientInfo(
            name: Strings.carbohydrates,
            value: summary.sum.Carb,
            percent: carbNorm > 0
                ? (summary.sum.Carb / carbNorm).clamp(0.0, 1.0)
                : 0,
          ),
        ],
      ),
    );
  }
}
