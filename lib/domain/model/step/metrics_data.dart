import 'package:freezed_annotation/freezed_annotation.dart';

part 'metrics_data.freezed.dart';
part 'metrics_data.g.dart';

@freezed
abstract class MetricsData with _$MetricsData {
  const factory MetricsData({required int foots, required double distance, required int kcal}) =
      _MetricsData;

  factory MetricsData.fromJson(Map<String, dynamic> json) => _$MetricsDataFromJson(json);
}
