import 'package:flutter/cupertino.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'calora_ai_calculate_management.freezed.dart';

@freezed
abstract class CaloraAiCalculateState with _$CaloraAiCalculateState {
  const factory CaloraAiCalculateState({
    @Default(false) bool isLoading,
    @Default(0.0) double progressPercent,
    @Default(0) int finalScore,
    @Default(false) bool isCompleted,
    @Default([]) List<AnalysisItem> analysisItems,
  }) = _CaloraAiCalculateState;

  factory CaloraAiCalculateState.initial() => const CaloraAiCalculateState();
}

@freezed
abstract class AnalysisItem with _$AnalysisItem {
  const factory AnalysisItem({
    required String description,
    required Widget iconPath,
    required int percentage,
    required String status,
  }) = _AnalysisItem;
}

@freezed
sealed class CaloraAiCalculateEffect with _$CaloraAiCalculateEffect {
  const factory CaloraAiCalculateEffect.error(String message) = _CaloraAiCalculateEffectError;

  const factory CaloraAiCalculateEffect.analysisComplete() = _CaloraAiCalculateEffectAnalysisComplete;
}
