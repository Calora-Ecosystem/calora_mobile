import 'package:calora/domain/model/norms/norms.dart';
import 'package:calora/domain/model/nutrient/nutrient_data.dart';
import 'package:calora/domain/model/profile/profile_request.dart';
import 'package:calora/domain/model/step/metrics_request.dart';
import 'package:calora/domain/model/summary/summary_request.dart' hide NutrientData;
import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_management.freezed.dart';

@freezed
abstract class HomeState with _$HomeState {
  factory HomeState({
    @Default(false) bool isLoading,
    @Default(false) bool isSummaryLoading,
    @Default(false) bool isWaterLoading,
    @Default(false) bool isMetricsLoading,
    @Default(0) int currentSteps,
    @Default(0) int targetSteps,
    @Default(0.0) double targetLiters,
    @Default(0.0) double targetKcal,
    @Default(0.0) double waterIntake,
    @Default(0.25) double bottleCapacity,
    @Default([]) List<NormsRequest> norms,
    @Default([]) List<NutrientInfo> nutrients,
    @Default(0) int unreadCount,
    DateTime? day,
    ProfileRequest? profile,
    SummaryRequest? summary,
    MetricsRequest? metrics,
  }) = _HomeState;
}

@freezed
class HomeEffect with _$HomeEffect {
  const factory HomeEffect.forceUpdate() = _ForceUpdate;
}
