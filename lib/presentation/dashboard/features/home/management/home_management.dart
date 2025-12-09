import 'package:calora/domain/model/norms/norms.dart';
import 'package:calora/domain/model/nutrient/nutrient_data.dart';
import 'package:calora/domain/model/profile/profile_request.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_management.freezed.dart';

@freezed
abstract class HomeState with _$HomeState {
  factory HomeState({
    ProfileRequest? profile,
    @Default(false) bool isLoading,
    @Default(0) double waterIntake,
    @Default([]) List<NormsRequest> norms,
    DateTime? day,
    @Default(0) double water,
    @Default(0) double remainedCalories,
    @Default([]) List<NutrientData> nutrients,
    @Default(0) int currentSteps,
    @Default(0) int targetSteps,
    @Default(0) double targetKcal,
    @Default(0) int timeInSeconds,
    @Default(0) double distanceInKm,
    @Default(0) int caloriesBurned,
    @Default(0.25) double bottleCapacity,
    @Default(0) double targetLiters,
  }) = _HomeState;

  factory HomeState.initial() => HomeState(day: DateTime.now());
}

@freezed
class HomeEffect with _$HomeEffect {
  const factory HomeEffect() = _HomeEffect;
}
