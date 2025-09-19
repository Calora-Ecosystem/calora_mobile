import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_norms_request.freezed.dart';
part 'daily_norms_request.g.dart';

@freezed
abstract class DailyNormsRequest with _$DailyNormsRequest {
  const factory DailyNormsRequest({
    required double calories,
    required double protein,
    required double fat,
    required double carbs,
    required double water,
    required double steps,
  }) = _DailyNormsRequest;

  factory DailyNormsRequest.fromJson(Map<String, dynamic> json) =>
      _$DailyNormsRequestFromJson(json);
}
