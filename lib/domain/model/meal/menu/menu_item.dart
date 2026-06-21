import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:calora/domain/model/meal/food/food_models.dart';

part 'menu_item.freezed.dart';
part 'menu_item.g.dart';

@freezed
abstract class MenuItem with _$MenuItem {
  const factory MenuItem({
    int? id,
    String? menu,
    DateTime? date,
    int? foodId,
    String? foodName,
    int? categoryId,
    String? categoryName,
    String? coverUrl,
    List<Metric>? metrics,
    int? userId,
    double? weight,
  }) = _MenuItem;

  factory MenuItem.fromJson(Map<String, dynamic> json) =>
      _$MenuItemFromJson(json);
}
