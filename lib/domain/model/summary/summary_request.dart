import 'package:freezed_annotation/freezed_annotation.dart';

part 'summary_request.freezed.dart';
part 'summary_request.g.dart';

@freezed
abstract class SummaryRequest with _$SummaryRequest {
  const factory SummaryRequest({required SummaryContent content}) = _SummaryRequest;

  factory SummaryRequest.fromJson(Map<String, dynamic> json) => _$SummaryRequestFromJson(json);
}

@freezed
abstract class SummaryContent with _$SummaryContent {
  const factory SummaryContent({
    required KcalNorm kcalNorm,
    required Map<String, NutrientData> nutrientsNorm,
    required Map<String, NutrientData> nutrients,
    required double sumKcal,
    required DateTime date,
  }) = _SummaryContent;

  factory SummaryContent.fromJson(Map<String, dynamic> json) => _$SummaryContentFromJson(json);
}

@freezed
abstract class KcalNorm with _$KcalNorm {
  const factory KcalNorm({required int userId, required String metric, required double value}) = _KcalNorm;

  factory KcalNorm.fromJson(Map<String, dynamic> json) => _$KcalNormFromJson(json);
}

@freezed
abstract class NutrientData with _$NutrientData {
  const factory NutrientData({
    required String menu,
    required double kcal,
    required double fat,
    required double protein,
    required double carb,
  }) = _NutrientData;

  factory NutrientData.fromJson(Map<String, dynamic> json) => _$NutrientDataFromJson(json);
}
