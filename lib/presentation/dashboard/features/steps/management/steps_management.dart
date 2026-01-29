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
    @Default(MetricsRequest(foots: 0, distance: 0, kcal: 0, duration: 0)) MetricsRequest dailyMetrics,
    @Default(MetricsRequest(foots: 0, distance: 0, kcal: 0, duration: 0)) MetricsRequest weeklyMetrics,
    @Default(MetricsRequest(foots: 0, distance: 0, kcal: 0, duration: 0)) MetricsRequest monthlyMetrics,
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
    @Default([]) List<UserStatRequest> dailyUserStates,
    @Default([]) List<UserStatRequest> weeklyUserStates,
    @Default([]) List<UserStatRequest> monthlyUserStates,
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
    @Default(false) bool isDailyLoading,
    @Default(false) bool isWeeklyLoading,
    @Default(false) bool isMonthlyLoading,
    @Default(false) bool hasLoadedTodayInitial,
  }) = _StepsState;

  const StepsState._();

  List<UserStatRequest> getUserStates() {
    List<UserStatRequest> currentPeriodUserStates;
    switch (period) {
      case 0:
        currentPeriodUserStates = dailyUserStates;
        break;
      case 1:
        currentPeriodUserStates = weeklyUserStates;
        break;
      case 2:
        currentPeriodUserStates = monthlyUserStates;
        break;
      default:
        currentPeriodUserStates = [];
        break;
    }
    if (currentPeriodUserStates.length <= 3) return [];
    return currentPeriodUserStates.sublist(3);
  }

  bool get canGoForward {
    switch (period) {
      case 0:
        return dailyOffset < 0;
      case 1:
        return weeklyOffset < 0;
      case 2:
        return monthlyOffset < 0;
      default:
        return false;
    }
  }

  int get currentStepCount {
    switch (period) {
      case 0:
        return dailyOffset == 0 ? stepCount : dailyDisplayStepCount;
      case 1:
        return weeklyDisplayStepCount;
      case 2:
        return monthlyDisplayStepCount;
      default:
        return 0;
    }
  }
}

@freezed
class StepsEffect with _$StepsEffect {
  const factory StepsEffect() = _StepsEffect;
}
