import 'package:calora/domain/model/dailies/steps_stat.dart';
import 'package:calora/domain/model/norms/norms.dart';
import 'package:calora/domain/model/step/metrics_request.dart';
import 'package:calora/domain/model/user/user_stat.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'steps_management.freezed.dart';

@freezed
abstract class StepsState with _$StepsState {
  const factory StepsState({
    @Default([]) List<StepsWithMetricsRequest> dailySteps,
    @Default([]) List<StepsWithMetricsRequest> weeklySteps,
    @Default([]) List<StepsWithMetricsRequest> monthlySteps,
    @Default(MetricsRequest(foots: 0, distance: 0, kcal: 0))
    MetricsRequest dailyMetrics,
    @Default(MetricsRequest(foots: 0, distance: 0, kcal: 0))
    MetricsRequest weeklyMetrics,
    @Default(MetricsRequest(foots: 0, distance: 0, kcal: 0))
    MetricsRequest monthlyMetrics,
    @Default([]) List<double> dailyPrimaryValues,
    @Default([]) List<double> weeklyPrimaryValues,
    @Default([]) List<double> monthlyPrimaryValues,
    @Default(0) int dailyDisplayStepCount,
    @Default(0) int weeklyDisplayStepCount,
    @Default(0) int monthlyDisplayStepCount,
    @Default('') String dailyFrom,
    @Default('') String weeklyFrom,
    @Default('') String monthlyFrom,
    @Default('') String dailyTo,
    @Default('') String weeklyTo,
    @Default('') String monthlyTo,
    @Default([]) List<NormsRequest> norms,
    @Default([]) List<UserStatRequest> userStates,
    @Default(0) int stepCount,
    @Default(0) int period,
    @Default(0) int dailyOffset,
    @Default(0) int weeklyOffset,
    @Default(0) int monthlyOffset,
    @Default(false) bool isGettingSteps,
    @Default(false) bool isGettingStats,
    @Default(false) bool isGettingUserMetrics,
    @Default(false) bool isUpdatingNorm,
    @Default(false) bool isGettingNorms,
    @Default(false) bool isDeletingNorm,
    @Default(false) bool isDeletingUserDailyData,
  }) = _StepsState;

  const StepsState._();

  List<UserStatRequest> getUserStates() {
    if (userStates.length <= 3) return [];
    return userStates.sublist(3);
  }

  bool get canGoForward => offset < 0;

  int get currentStepCount {
    if (period == 0 && offset == 0) {
      return stepCount;
    }
    if (period == 0) return dailyDisplayStepCount;
    if (period == 1) return weeklyDisplayStepCount;
    return monthlyDisplayStepCount;
  }
}

@freezed
class StepsEffect with _$StepsEffect {
  const factory StepsEffect() = _StepsEffect;
}
