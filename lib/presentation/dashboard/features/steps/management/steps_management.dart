import 'package:calora/domain/model/user/user_stat.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'steps_management.freezed.dart';

@freezed
abstract class StepsState with _$StepsState {
  const factory StepsState({
    @Default(0) int stepCount,
    @Default(0) int metrics,
    @Default(0) int statsTotal,
    @Default([]) List<UserStat> userStates,
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
