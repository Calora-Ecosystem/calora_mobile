import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class FoodCreatorWithSpeech extends StatelessWidget {
  final List<String> meals;
  final VoidCallback onAdd;

  const FoodCreatorWithSpeech({super.key, required this.meals, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    Strings.meals.text(20, 24, 700).c(context.colors.textStrong),
                    SizedBox(height: 4),
                    Strings.foodsIdentifiedByVoiceMessage.text(16, 20, 500).c(context.colors.textStrong),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: meals.map((item) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          decoration: BoxDecoration(
                            color: context.colors.blackWithOpacity,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: item.text(14, 16, 400).c(context.colors.textStrong),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                spacing: 16,
                children: [
                  Expanded(
                    child: Button(
                      onPressed: () => context.router.pop(),
                      text: Strings.cancel,
                      type: ButtonType.secondary,
                      textColor: context.colors.textStrong,
                    ),
                  ),
                  Expanded(
                    child: Button(onPressed: onAdd, text: Strings.add),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
