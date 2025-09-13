import 'package:freezed_annotation/freezed_annotation.dart';

part 'steps_response.freezed.dart';
part 'steps_response.g.dart';

@freezed
abstract class StepsResponse with _$StepsResponse {
  const factory StepsResponse({int? total}) = _StepsResponse;

  factory StepsResponse.fromJson(Map<String, dynamic> json) => _$StepsResponseFromJson(json);
}
