import 'package:freezed_annotation/freezed_annotation.dart';

part 'face_analysis_model.freezed.dart';
part 'face_analysis_model.g.dart';

@freezed
sealed class FaceAnalysisModel with _$FaceAnalysisModel {
  const factory FaceAnalysisModel({
    int? healthPercent,
    int? rashes,
    int? darkEyes,
    int? energy,
    int? stress,
    int? sleep,
  }) = _FaceAnalysisModel;

  factory FaceAnalysisModel.fromJson(Map<String, dynamic> json) =>
      _$FaceAnalysisModelFromJson(json);
}
