import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class DailyNormsList extends StatelessWidget {
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final double water;
  final double steps;

  final VoidCallback? onCaloriesTap;
  final VoidCallback? onProteinTap;
  final VoidCallback? onFatTap;
  final VoidCallback? onCarbsTap;
  final VoidCallback? onWaterTap;
  final VoidCallback? onStepsTap;

  const DailyNormsList({
    super.key,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.water,
    required this.steps,
    this.onCaloriesTap,
    this.onProteinTap,
    this.onFatTap,
    this.onCarbsTap,
    this.onWaterTap,
    this.onStepsTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {"title": Strings.dailyCalorieIntake, "value": '$calories kkal', "onTap": onCaloriesTap},
      {"title": Strings.dailyProteinIntake, "value": '$protein gr', "onTap": onProteinTap},
      {"title": Strings.dailyFatIntake, "value": '$fat gr', "onTap": onFatTap},
      {"title": Strings.dailyCarbohydradeIntake, "value": '$carbs gr', "onTap": onCarbsTap},
      {"title": Strings.dailyWaterIntake, "value": '$water ml', "onTap": onWaterTap},
      {"title": Strings.dailyStepRate, "value": '$steps qadam', "onTap": onStepsTap},
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length + 1,
      separatorBuilder: (_, __) => Divider(height: 1, color: context.colors.strokeSoft),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return Divider(height: 1, color: context.colors.strokeSoft);
        }
        final item = items[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: (item["title"]! as String).text(14, 16, 400).c(context.colors.textStrong),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              (item["value"]! as String).text(14, 16, 400),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
          onTap: item["onTap"] as VoidCallback?,
        );
      },
    );
  }
}
