import 'package:calora/common/extensions/gradient_text_extension.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class EditStepGoalPage extends StatefulWidget {
  final int initialValue;
  final ValueChanged<int> onSave;

  const EditStepGoalPage({super.key, required this.initialValue, required this.onSave});

  @override
  State<EditStepGoalPage> createState() => _EditStepGoalPageState();
}

class _EditStepGoalPageState extends State<EditStepGoalPage> {
  late FixedExtentScrollController _controller;
  late int _selectedValue;

  Shader linearGradient = const LinearGradient(
    colors: <Color>[Color(0xFFEEEEEE), Color(0xFF999999)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0));

  @override
  void initState() {
    super.initState();
    int initialValue = widget.initialValue;

    if (initialValue <= 0) {
      initialValue = 10000;
    }

    int initialItemIndex = (initialValue / 1000).round() - 1;

    if (initialItemIndex < 0) {
      initialItemIndex = 0;
    } else if (initialItemIndex >= 50) {
      initialItemIndex = 49;
    }

    _selectedValue = (initialItemIndex + 1) * 1000;
    _controller = FixedExtentScrollController(initialItem: initialItemIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 3,
            decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
          ),
          SizedBox(height: 12),
          Align(
            alignment: AlignmentGeometry.topLeft,
            child: Strings.stepsToSetAGoal.text(20, 24, 700).c(context.colors.textStrong),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListWheelScrollView.useDelegate(
              controller: _controller,
              itemExtent: 40,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (index) {
                setState(() => _selectedValue = (index + 1) * 1000);
              },
              childDelegate: ListWheelChildBuilderDelegate(
                builder: (context, index) {
                  final value = (index + 1) * 1000;
                  final isSelected = value == _selectedValue;
                  final isAbove = value == _selectedValue - 1000;
                  final isBelow = value == _selectedValue + 1000;

                  LinearGradient gradient;

                  if (isSelected) {
                    gradient = LinearGradient(
                      colors: [
                        context.colors.defaultText,
                        context.colors.defaultText,
                      ],
                    );
                  } else if (isAbove) {
                    gradient = LinearGradient(
                      colors: [
                        context.colors.white,
                        context.colors.defaultText,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    );
                  } else if (isBelow) {
                    gradient = LinearGradient(
                      colors: [
                        context.colors.defaultText,
                        context.colors.white,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    );
                  } else {
                    gradient = LinearGradient(
                      colors: const [Colors.grey, Colors.grey],
                    );
                  }
                  return Center(
                    child: value.toString().text(32, 40, 700).c(context.colors.defaultText).gradient(gradient),
                  );
                },
                childCount: 50,
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              widget.onSave(_selectedValue);
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: context.colors.accentSub,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Strings.save.text(16, 20, 500).c(context.colors.white).copyWith(textAlign: TextAlign.center),
            ),
          ),
          SizedBox(height: 28),
        ],
      ),
    );
  }
}
