import 'package:freezed_annotation/freezed_annotation.dart';

part 'norms.freezed.dart';
part 'norms.g.dart';

@freezed
abstract class NormsRequest with _$NormsRequest {
  const factory NormsRequest({required String metric, required int value}) = _NormsRequest;

  factory NormsRequest.fromJson(Map<String, dynamic> json) => _$NormsRequestFromJson(json);
}
