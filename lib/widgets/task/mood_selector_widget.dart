import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class MoodSelector extends StatefulWidget {
  const MoodSelector({super.key});

  @override
  State<MoodSelector> createState() => _MoodSelectorState();
}

class _MoodSelectorState extends State<MoodSelector> {
  String? selectedMood;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildMoodButton(icon: Assets.icons.sad.svg(), label: Strings.heavy, value: 'heavy'),
        SizedBox(width: 20),
        _buildMoodButton(
          icon: Assets.icons.neutral.svg(),
          label: Strings.average,
          value: 'average',
        ),
        SizedBox(width: 20),
        _buildMoodButton(icon: Assets.icons.smile.svg(), label: Strings.good, value: 'good'),
      ],
    );
  }

  Widget _buildMoodButton({required Widget icon, required String label, required String value}) {
    final isSelected = selectedMood == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedMood = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: context.colors.backgroundElevation,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? context.colors.accentSub : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(height: 4),
              label.text(16, 20, 500).c(context.colors.textStrong),
            ],
          ),
        ),
      ),
    );
  }
}
