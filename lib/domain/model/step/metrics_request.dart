import 'package:freezed_annotation/freezed_annotation.dart';

part 'metrics_request.freezed.dart';
part 'metrics_request.g.dart';

@freezed
abstract class MetricsRequest with _$MetricsRequest {
  const factory MetricsRequest({
    required int foots,
    required double distance,
    required int kcal,
    required num duration,
  }) = _MetricsRequest;

  factory MetricsRequest.fromJson(Map<String, dynamic> json) => _$MetricsRequestFromJson(json);
}
