import 'package:freezed_annotation/freezed_annotation.dart';

part 'calora_ai_management.freezed.dart';

@freezed
abstract class CaloraAiState with _$CaloraAiState {
  const factory CaloraAiState() = _CaloraAiState;
}

@freezed
abstract class CaloraAiEffect with _$CaloraAiEffect {
  const factory CaloraAiEffect.showConfirmDialog() = _ShowConfirmDialog;

  const factory CaloraAiEffect.navigateToCamera() = _NavigateToCamera;
}
