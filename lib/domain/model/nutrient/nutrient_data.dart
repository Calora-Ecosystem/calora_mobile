import 'package:calora/common/gen/strings.dart';

class NutrientInfo {
  final String name;
  final double value;
  final double percent;

  NutrientInfo({
    required this.name,
    required this.value,
    required this.percent,
  });
}

final List<NutrientInfo> defaultNutrients = [
  NutrientInfo(name: Strings.oils, value: 49.3, percent: 0.5),
  NutrientInfo(name: Strings.proteins, value: 32.7, percent: 0.7),
  NutrientInfo(name: Strings.carbohydrates, value: 68.2, percent: 0.6),
];
