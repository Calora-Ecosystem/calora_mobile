import 'package:calora/domain/model/dailies/steps_stat.dart';
import 'package:calora/domain/model/norms/norms.dart';
import 'package:calora/domain/model/step/metrics_data.dart';
import 'package:calora/domain/model/user/user_stat.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'steps_management.freezed.dart';

@freezed
abstract class StepsState with _$StepsState {
  const factory StepsState({
    @Default([]) List<StepsWithMetrics> steps,
    @Default(MetricsData(foots: 100, distance: 50, kcal: 50)) MetricsData metrics,
    @Default([Norms(metric: 'metric', value: 200)]) List<Norms> norms,
    @Default([]) List<UserStat> userStates,
    @Default(0) int stepCount,
    @Default(false) bool isLoading,
  }) = _StepsState;

  const StepsState._();

  List<UserStat> getUserStates() {
    if (userStates.length <= 3) {
      return [];
    }
    return userStates.sublist(3, userStates.length);
  }
}

@freezed
class StepsEffect with _$StepsEffect {
  const factory StepsEffect() = _StepsEffect;
}
