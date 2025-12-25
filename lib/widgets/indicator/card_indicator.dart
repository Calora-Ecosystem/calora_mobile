import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class CardIndicator extends StatelessWidget {
  final double percent;
  const CardIndicator({super.key, required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Strings.done.text(10, 12, 500),
              '${(percent * 100).toInt()}%'.text(10, 12, 500),
            ],
          ),
          const SizedBox(height: 8),
          LinearPercentIndicator(
            padding: EdgeInsets.all(0),
            lineHeight: 8.0,
            percent: percent,
            barRadius: const Radius.circular(8),
            progressColor: context.colors.informationBase,
            backgroundColor: context.colors.informationLighter,
            animation: true,
          ),
        ],
      ),
    );
  }
}
