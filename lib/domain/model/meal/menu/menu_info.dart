import 'package:freezed_annotation/freezed_annotation.dart';

part 'menu_info.freezed.dart';
part 'menu_info.g.dart';

@freezed
abstract class MenuInfo with _$MenuInfo {
  const factory MenuInfo({
    required String menu,
    required DateTime date,
    required int foodId,
    required int weightInGr,
  }) = _MenuInfo;

  factory MenuInfo.fromJson(Map<String, dynamic> json) =>
      _$MenuInfoFromJson(json);
}
