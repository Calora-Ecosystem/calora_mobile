import 'package:calora/common/extensions/color_extension.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class CustomSwitch extends StatefulWidget {
  final bool initialValue;
  final void Function(bool)? onChanged;
  final double width;
  final double height;
  final Color? activeColor;
  final Color? inactiveColor;
  final Duration duration;
  final EdgeInsets margin;

  const CustomSwitch({
    super.key,
    required this.initialValue,
    this.onChanged,
    this.width = 51,
    this.height = 31,
    this.activeColor,
    this.inactiveColor,
    this.duration = const Duration(milliseconds: 200),
    this.margin = EdgeInsets.zero,
  });

  @override
  State<CustomSwitch> createState() => _CustomSwitchState();
}

class _CustomSwitchState extends State<CustomSwitch> {
  late bool isOn;

  @override
  void initState() {
    super.initState();
    isOn = widget.initialValue;
  }

  @override
  void didUpdateWidget(covariant CustomSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      setState(() => isOn = widget.initialValue);
    }
  }

  void toggleSwitch() {
    final newValue = !isOn;
    setState(() => isOn = newValue);
    widget.onChanged?.call(newValue);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.margin,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: toggleSwitch,
        child: AnimatedContainer(
          duration: widget.duration,
          width: widget.width,
          height: widget.height,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isOn
                ? (widget.activeColor ?? context.colors.accentSub)
                : (widget.inactiveColor ?? context.colors.zirkon),
            borderRadius: BorderRadius.circular(widget.height / 2),
          ),
          child: AnimatedAlign(
            duration: widget.duration,
            alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: widget.height - 8,
              height: widget.height - 8,
              decoration: BoxDecoration(
                color: context.colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, 3),
                    blurRadius: 1,
                    color: Colors.black.withOpacityLevel(0.06),
                  ),
                  BoxShadow(
                    offset: const Offset(0, 3),
                    blurRadius: 8,
                    color: Colors.black.withOpacityLevel(0.15),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
