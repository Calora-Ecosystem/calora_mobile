import 'package:calora/common/gen/strings.dart';

class NutrientData {
  final String name;
  final double value;
  final double percent;

  NutrientData({
    required this.name,
    required this.value,
    required this.percent,
  });
}

final List<NutrientData> defaultNutrients = [
  NutrientData(name: Strings.oils, value: 49.3, percent: 0.5),
  NutrientData(name: Strings.proteins, value: 32.7, percent: 0.7),
  NutrientData(name: Strings.carbohydrates, value: 68.2, percent: 0.6),
];
