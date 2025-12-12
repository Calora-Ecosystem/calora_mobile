// metric_type.dart
import 'package:calora/domain/model/meal/food/food_models.dart';
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
    return MetricType.values.firstWhere((e) => e.value == value, orElse: () => MetricType.protein);
  }
}

// Helper class
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

// FoodItem extension
extension FoodItemMetrics on FoodItem {
  double getMetricValue(MetricType type) => MetricsHelper.getMetricValue(metrics, type);

  double get proteins => getMetricValue(MetricType.protein);

  double get fats => getMetricValue(MetricType.fat);

  double get carbohydrates => getMetricValue(MetricType.carb);

  double get calories => getMetricValue(MetricType.kcal);

  double get water => getMetricValue(MetricType.water);

  double get steps => getMetricValue(MetricType.step);

  double get weight => getMetricValue(MetricType.weight);
}

// MenuItem extension
extension MenuItemMetrics on MenuItem {
  double getMetricValue(MetricType type) => MetricsHelper.getMetricValue(metrics, type);

  double get proteins => getMetricValue(MetricType.protein);

  double get fats => getMetricValue(MetricType.fat);

  double get carbohydrates => getMetricValue(MetricType.carb);

  double get calories => getMetricValue(MetricType.kcal);

  double get water => getMetricValue(MetricType.water);

  double get steps => getMetricValue(MetricType.step);

  double get weight => getMetricValue(MetricType.weight);
}
