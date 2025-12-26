import 'package:freezed_annotation/freezed_annotation.dart';

part 'dailies_request.freezed.dart';

part 'dailies_request.g.dart';

@freezed
abstract class DailiesRequest with _$DailiesRequest {
  const factory DailiesRequest({
    required String metric,
    required double value,
    required String date,
  }) = _DailiesRequest;

  factory DailiesRequest.fromJson(Map<String, dynamic> json) => _$DailiesRequestFromJson(json);
}
