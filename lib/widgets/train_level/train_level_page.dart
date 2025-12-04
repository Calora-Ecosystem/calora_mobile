import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/questions/purposes_widget.dart';
import 'package:flutter/material.dart';

class TrainLevelPage extends StatefulWidget {
  final ValueChanged<int> onSave;

  const TrainLevelPage({super.key, required this.onSave});

  @override
  State<TrainLevelPage> createState() => _TrainLevelPageState();
}

class _TrainLevelPageState extends State<TrainLevelPage> {
  int level = 0;

  @override
  Widget build(BuildContext context) {
    List<String> degrees = [
      Strings.easyStart,
      Strings.withoutOverload,
      Strings.returnToActivity,
      Strings.increaseActivity,
      Strings.highLevelActivity,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: IntrinsicHeight(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Strings.chooseYourWorkoutLevel.text(20, 24, 700).c(context.colors.textStrong),
            const SizedBox(height: 16),
            PurposesWidget(
              goals: degrees,
              onPurposeSelected: (value) {
                setState(() {
                  level = value;
                });
              },
            ),
            const SizedBox(height: 36),
            GestureDetector(
              onTap: () {
                widget.onSave(level);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: context.colors.accentSub,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Strings.save
                    .text(16, 20, 500)
                    .c(context.colors.white)
                    .copyWith(textAlign: TextAlign.center),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
