import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class Goals extends StatefulWidget {
  final List<String> goals;
  final ValueChanged<int>? onGoalSelected;
  final int? initialSelectedIndex;

  const Goals({super.key, required this.goals, this.onGoalSelected, this.initialSelectedIndex});

  @override
  State<Goals> createState() => _GoalsState();
}

class _GoalsState extends State<Goals> {
  int? selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialSelectedIndex;
  }

  void _selectGoal(int index) {
    setState(() {
      selectedIndex = index;
    });
    widget.onGoalSelected?.call(index);
  }

  Widget goalButton(int index, String label) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => _selectGoal(index),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 26),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? context.colors.strokeAccent : Colors.transparent,
            width: 1,
          ),
          color: context.colors.commonBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: label
            .text(14, 16, 400)
            .c(context.colors.textStrong)
            .copyWith(textAlign: TextAlign.center),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < widget.goals.length; i++) ...[
          goalButton(i, widget.goals[i]),
          if (i < widget.goals.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}
