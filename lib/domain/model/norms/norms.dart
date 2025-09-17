import 'package:freezed_annotation/freezed_annotation.dart';

part 'norms.freezed.dart';
part 'norms.g.dart';

@freezed
abstract class Norms with _$Norms {
  const factory Norms({required String metric, required int value}) = _Norms;

  factory Norms.fromJson(Map<String, dynamic> json) => _$NormsFromJson(json);
}
