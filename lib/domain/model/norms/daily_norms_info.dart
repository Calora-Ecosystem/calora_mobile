import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_norms_info.freezed.dart';
part 'daily_norms_info.g.dart';

@freezed
abstract class DailyNormsInfo with _$DailyNormsInfo {
  const factory DailyNormsInfo({
    required double calories,
    required double protein,
    required double fat,
    required double carbs,
    required double water,
    required double steps,
  }) = _DailyNormsInfo;

  factory DailyNormsInfo.fromJson(Map<String, dynamic> json) =>
      _$DailyNormsInfoFromJson(json);
}
