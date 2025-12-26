import 'package:freezed_annotation/freezed_annotation.dart';

part 'summary_request.freezed.dart';
part 'summary_request.g.dart';

@freezed
abstract class SummaryRequest with _$SummaryRequest {
  const factory SummaryRequest({
    required KcalNorm kcalNorm,
    required Map<String, NutrientData> nutrientsNorm,
    required Map<String, NutrientData> nutrients,
    required SumData sum,
    required DateTime date,
  }) = _SummaryRequest;

  factory SummaryRequest.fromJson(Map<String, dynamic> json) => _$SummaryRequestFromJson(json);
}

@freezed
abstract class KcalNorm with _$KcalNorm {
  const factory KcalNorm({
    required int userId,
    required String metric,
    required double value,
  }) = _KcalNorm;

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
    required double weight,
  }) = _NutrientData;

  factory NutrientData.fromJson(Map<String, dynamic> json) => _$NutrientDataFromJson(json);
}

@freezed
abstract class SumData with _$SumData {
  const factory SumData({
    required double Kcal,
    required double Carb,
    required double Protein,
    required double Fat,
  }) = _SumData;

  factory SumData.fromJson(Map<String, dynamic> json) => _$SumDataFromJson(json);
}
