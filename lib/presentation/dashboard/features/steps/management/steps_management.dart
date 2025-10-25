import 'package:calora/domain/model/dailies/steps_stat.dart';
import 'package:calora/domain/model/norms/norms.dart';
import 'package:calora/domain/model/step/metrics_request.dart';
import 'package:calora/domain/model/user/user_stat.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'steps_management.freezed.dart';

@freezed
abstract class StepsState with _$StepsState {
  const factory StepsState({
    @Default([]) List<StepsWithMetricsRequest> steps,
    @Default(MetricsRequest(foots: 0.0, distance: 0, kcal: 0)) MetricsRequest metrics,
    @Default([]) List<NormsRequest> norms,
    @Default([]) List<double> primaryValues,
    @Default([]) List<UserStatRequest> userStates,
    @Default(0) int stepCount,
    @Default(0) int displayStepCount,
    @Default(0) int period,
    @Default(0) int offset,
    @Default(false) bool isLoading,
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
    return displayStepCount;
  }
}

@freezed
class StepsEffect with _$StepsEffect {
  const factory StepsEffect() = _StepsEffect;
}
