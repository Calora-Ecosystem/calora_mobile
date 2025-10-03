import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class ToggleButtonsWidget extends StatefulWidget {
  final ValueChanged<int> onChanged;
  final String firstTitle;
  final String secondTitle;

  const ToggleButtonsWidget({
    super.key,
    required this.onChanged,
    required this.firstTitle,
    required this.secondTitle,
  });

  @override
  State<ToggleButtonsWidget> createState() => _ToggleButtonsWidgetState();
}

class _ToggleButtonsWidgetState extends State<ToggleButtonsWidget> {
  int selectedIndex = 0;

  Widget _buildButton({required String title, required int index}) {
    final bool isActive = selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedIndex = index;
          });
          widget.onChanged(selectedIndex);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? context.colors.accentSub : context.colors.backgroundElevation,
            borderRadius: BorderRadius.circular(8),
          ),
          child: title
              .text(14, 16, 400)
              .c(isActive ? context.colors.white : context.colors.textStrong)
              .copyWith(textAlign: TextAlign.center),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildButton(title: widget.firstTitle, index: 0),
        const SizedBox(width: 8),
        _buildButton(title: widget.secondTitle, index: 1),
      ],
    );
  }
}
