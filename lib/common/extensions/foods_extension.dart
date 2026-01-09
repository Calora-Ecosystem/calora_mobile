// metric_type.dart
import 'package:calora/domain/model/meal/food/food_models.dart';
import 'package:calora/domain/model/meal/food_request/food_request.dart';
import 'package:calora/domain/model/meal/menu/menu_info.dart';
import 'package:calora/domain/model/meal/menu/menu_item.dart';

enum MetricType {
  protein('Protein'),
  fat('Fat'),
  carb('Carb'),
  kcal('Kcal'),
  water('Water'),
  step('Step'),
  weight('Weight');

  final String value;

  const MetricType(this.value);

  static MetricType? fromString(String value) {
    return MetricType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MetricType.protein,
    );
  }
}

class MetricsHelper {
  static double getMetricValue(List<Metric> metrics, MetricType type) {
    try {
      final metric = metrics.firstWhere((m) => m.metric == type.value);
      return metric.value.toDouble();
    } catch (e) {
      return 0.0;
    }
  }
}

extension ScannerFoodMapper on ScannerFood {
  FoodRequest toFoodRequest({
    required int categoryId,
    required int userId,
    required String coverUrl,
  }) {
    return FoodRequest(
      categoryId: categoryId,
      name: FoodName(uz: name, ru: name, eng: name, cyrl: name),
      coverUrl: coverUrl,
      metrics: metrics,
      userId: userId,
    );
  }

  MenuInfo toMenuInfo({
    required String menu,
    required DateTime date,
    required int foodId,
  }) {
    return MenuInfo(menu: menu, date: date, foodId: foodId, weightInGr: weight);
  }
}

extension FoodModelMetrics on FoodModel {
  double get cal => MetricsHelper.getMetricValue(metrics, MetricType.kcal);

  double get proteins =>
      MetricsHelper.getMetricValue(metrics, MetricType.protein);

  double get fats => MetricsHelper.getMetricValue(metrics, MetricType.fat);

  double get carbohydrates =>
      MetricsHelper.getMetricValue(metrics, MetricType.carb);

  double get water => MetricsHelper.getMetricValue(metrics, MetricType.water);

  double get steps => MetricsHelper.getMetricValue(metrics, MetricType.step);

  double get weight => MetricsHelper.getMetricValue(metrics, MetricType.weight);
}

// MenuItem extension
extension MenuItemMetrics on MenuItem {
  double getMetricValue(MetricType type) =>
      MetricsHelper.getMetricValue(metrics, type);

  double get proteins => getMetricValue(MetricType.protein);

  double get fats => getMetricValue(MetricType.fat);

  double get carbohydrates => getMetricValue(MetricType.carb);

  double get calories => getMetricValue(MetricType.kcal);

  double get water => getMetricValue(MetricType.water);

  double get steps => getMetricValue(MetricType.step);
}
