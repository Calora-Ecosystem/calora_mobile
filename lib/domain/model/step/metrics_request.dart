import 'package:freezed_annotation/freezed_annotation.dart';

part 'metrics_request.freezed.dart';
part 'metrics_request.g.dart';

@freezed
abstract class MetricsRequest with _$MetricsRequest {
  const factory MetricsRequest({required double foots, required double distance, required double kcal}) =
      _MetricsRequest;

  factory MetricsRequest.fromJson(Map<String, dynamic> json) => _$MetricsRequestFromJson(json);
}
