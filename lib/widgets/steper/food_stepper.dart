import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class FoodStepper extends StatefulWidget {
  final int initialValue;
  final ValueChanged<int>? onChanged;

  const FoodStepper({super.key, this.initialValue = 1, this.onChanged});

  @override
  State<FoodStepper> createState() => _FoodStepperState();
}

class _FoodStepperState extends State<FoodStepper> {
  late int value;

  @override
  void initState() {
    super.initState();
    value = widget.initialValue;
  }

  void _increment() {
    setState(() {
      value++;
      widget.onChanged?.call(value);
    });
  }

  void _decrement() {
    setState(() {
      if (value > 1) {
        value--;
        widget.onChanged?.call(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _decrement,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: context.colors.backgroundElevation, shape: BoxShape.circle),
            child: const Icon(Icons.remove, color: Colors.black87, size: 24),
          ),
        ),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 24.0), child: value.toString().text(32, 40, 700)),
        GestureDetector(
          onTap: _increment,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: context.colors.backgroundElevation, shape: BoxShape.circle),
            child: const Icon(Icons.add, color: Colors.black87, size: 24),
          ),
        ),
      ],
    );
  }
}
