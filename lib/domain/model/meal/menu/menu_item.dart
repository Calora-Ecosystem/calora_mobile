import 'package:freezed_annotation/freezed_annotation.dart';

import '../food/food_models.dart';

part 'menu_item.freezed.dart';
part 'menu_item.g.dart';

@freezed
abstract class MenuItem with _$MenuItem {
  const factory MenuItem({
    required String menu,
    required DateTime date,
    required int foodId,
    required String foodName,
    required int categoryId,
    required String categoryName,
    required String coverUrl,
    required List<Metric> metrics,
    int? userId,
    required double weight,
  }) = _MenuItem;

  factory MenuItem.fromJson(Map<String, dynamic> json) => _$MenuItemFromJson(json);
}
