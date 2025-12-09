import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class ToggleButtonsWidget extends StatefulWidget {
  final ValueChanged<int> onChanged;
  final List<String> titles;
  final int initialIndex;

  const ToggleButtonsWidget({super.key, required this.onChanged, required this.titles, this.initialIndex = 0})
    : assert(titles.length > 0, 'At least one button is required');

  @override
  State<ToggleButtonsWidget> createState() => _ToggleButtonsWidgetState();
}

class _ToggleButtonsWidgetState extends State<ToggleButtonsWidget> {
  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
  }

  Widget _buildButton({required String title, required int index}) {
    final bool isActive = selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
        widget.onChanged(selectedIndex);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? context.colors.accentSub : context.colors.backgroundElevation,
          borderRadius: BorderRadius.circular(8),
        ),
        child: title
            .text(14, 16, 400)
            .c(isActive ? context.colors.white : context.colors.textStrong)
            .copyWith(textAlign: TextAlign.center),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(widget.titles.length * 2 - 1, (index) {
          if (index.isOdd) {
            return const SizedBox(width: 8);
          }
          final buttonIndex = index ~/ 2;
          return _buildButton(title: widget.titles[buttonIndex], index: buttonIndex);
        }),
      ),
    );
  }
}
