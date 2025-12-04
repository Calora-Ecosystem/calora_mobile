import 'package:calora/common/gen/assets.gen.dart';
import 'package:flutter/material.dart';

enum Level { easy, withoutOverload, returnToActivity, increaseActivity, high }

class RatingStars extends StatelessWidget {
  final Level level;

  const RatingStars({super.key, required this.level});

  int get filledStars {
    switch (level) {
      case Level.easy:
        return 1;
      case Level.withoutOverload:
        return 2;
      case Level.returnToActivity:
        return 3;
      case Level.increaseActivity:
        return 4;
      case Level.high:
        return 5;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isFilled = index < filledStars;
        return isFilled ? Assets.icons.fullStar.svg() : Assets.icons.lightStar.svg();
      }),
    );
  }
}
