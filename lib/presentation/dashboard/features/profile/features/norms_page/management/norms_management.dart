import 'package:calora/domain/model/norms/daily_norms_request.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'norms_management.freezed.dart';

@freezed
abstract class NormsState with _$NormsState {
  const factory NormsState({
    @Default(DailyNormsRequest(calories: 0, protein: 0, fat: 0, carbs: 0, water: 0, steps: 0))
    DailyNormsRequest dailyNorms,
  }) = _NormsState;
}

@freezed
class NormsEffect with _$NormsEffect {}
