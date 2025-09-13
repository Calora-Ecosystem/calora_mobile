import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class QuestionProgressWidget extends StatelessWidget {
  final int current;
  final int total;

  const QuestionProgressWidget({super.key, required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 65,

      decoration: BoxDecoration(
        color: context.colors.backgroundBase,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Strings.weHaveQuestions.text(16, 20, 500).c(context.colors.textStrong),
                Text(
                  "$current/$total",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                    color: Color(0xFF46A758),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                total,
                (index) => Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: index < current
                          ? context.colors.accentSoft
                          : context.colors.strokeSoft,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
