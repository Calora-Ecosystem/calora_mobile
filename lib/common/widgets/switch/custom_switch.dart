import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class CustomSwitch extends StatefulWidget {
  final Function(bool result) result;
  bool value;

  CustomSwitch({super.key, this.value = false, required this.result});

  @override
  State<CustomSwitch> createState() => _CustomSwitchState();
}

class _CustomSwitchState extends State<CustomSwitch> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          widget.value = !widget.value;
        });
        widget.result(widget.value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 44.0,
        height: 24.0,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          color: widget.value ? context.colors.accentSub : context.colors.backgroundElevation,
        ),
        child: Stack(
          children: <Widget>[
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeIn,
              top: 2.0,
              bottom: 2.0,
              left: widget.value ? 20.0 : 0.0,
              right: widget.value ? 0.0 : 20.0,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(child: child, scale: animation);
                },
                child: Container(
                  height: 20.0,
                  width: 20.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 2,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
