import 'package:calora/common/gen/assets.gen.dart';
import 'package:flutter/material.dart';

enum StepperType { int, duration }

class UniversalStepperWidget extends StatefulWidget {
  final StepperType type;

  final int initialInt;
  final int stepInt;
  final int totalInt;

  final Duration initialDuration;
  final Duration stepDuration;

  final TextStyle? styleInt;
  final TextStyle? styleDuration;

  final ValueChanged<dynamic>? onChanged;

  const UniversalStepperWidget({
    super.key,
    required this.type,

    this.initialInt = 1,
    this.stepInt = 1,
    this.totalInt = 1,

    this.initialDuration = const Duration(seconds: 30),
    this.stepDuration = const Duration(seconds: 10),

    this.styleInt,
    this.styleDuration,

    this.onChanged,
  });

  @override
  State<UniversalStepperWidget> createState() => _UniversalStepperWidgetState();
}

class _UniversalStepperWidgetState extends State<UniversalStepperWidget> {
  late dynamic value;

  @override
  void initState() {
    super.initState();
    value = widget.type == StepperType.int ? widget.initialInt : widget.initialDuration;
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds.remainder(60))}';
  }

  void _increment() {
    setState(() {
      if (widget.type == StepperType.int) {
        if (value < widget.totalInt) {
          value += widget.stepInt;
        }
      } else {
        value += widget.stepDuration;
      }
    });
    widget.onChanged?.call(value);
  }

  void _decrement() {
    setState(() {
      if (widget.type == StepperType.int) {
        if (value > 1) value -= widget.stepInt;
      } else {
        if (value > widget.stepDuration) {
          value -= widget.stepDuration;
        }
      }
    });
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final textWidget = widget.type == StepperType.int
        ? Text(
            '$value/${widget.totalInt}',
            style:
                widget.styleInt ??
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 0.8),
          )
        : Text(
            _formatDuration(value),
            style:
                widget.styleDuration ??
                const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 0.83),
          );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: widget.type == StepperType.int
              ? Assets.icons.arrowLeft.svg()
              : const Icon(Icons.remove),
          onPressed: _decrement,
        ),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: textWidget),
        IconButton(
          icon: widget.type == StepperType.int
              ? Assets.icons.arrowRight.svg()
              : const Icon(Icons.add),
          onPressed: _increment,
        ),
      ],
    );
  }
}
