import 'package:calora/common/di/injection.dart';
import 'package:calora/common/widgets/display/display_message.dart';
import 'package:calora/common/widgets/display/message_widget.dart';
import 'package:flutter/material.dart';

import 'display.dart';

class DisplayWidget extends StatefulWidget {
  const DisplayWidget({super.key, required this.child});

  final Widget child;

  @override
  State<DisplayWidget> createState() => _DisplayWidgetState();
}

class _DisplayWidgetState extends State<DisplayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  DisplayMessage? message;

  @override
  Widget build(BuildContext context) {
    _initDisplay(context);
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        widget.child,
        if (message != null)
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -1),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Curves.easeInOut,
              ),
            ),
            child: AnimatedContainer(
              curve: Curves.easeInOut,
              duration: const Duration(seconds: 1),
              child: MessageWidget(
                message: message!,
                onClosed: () {
                  setState(() {
                    message = null;
                  });
                },
              ),
            ),
          ),
      ],
    );
  }

  void _initDisplay(BuildContext context) {
    final display = getIt<Display>();
    display.setOnDisplayListener((message) async {
      setState(() {
        this.message = message;
      });
      _animationController.reset();
      _animationController.forward();
      await Future.delayed(message.duration ?? const Duration(seconds: 5));
      if (this.message != message || !mounted) return;
      _animationController.reverse();
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() {
        this.message = null;
      });
    });
  }
}
