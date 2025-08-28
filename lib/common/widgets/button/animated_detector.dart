import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AnimatedDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;

  const AnimatedDetector({
    super.key,
    required this.child,
    this.onTap,
    this.enabled = true,
  });

  @override
  State<AnimatedDetector> createState() => _AnimatedDetectorState();
}

class _AnimatedDetectorState extends State<AnimatedDetector>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 0.95,
    ).animate(CurvedAnimation(curve: Curves.decelerate, parent: _controller));
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () async {
      if (widget.enabled) {
        widget.onTap?.call();
      }
    },
    onPanDown: (details) {
      if (widget.enabled) {
        _controller.forward();
      }
    },
    onTapCancel: () {
      if (widget.enabled) {
        _controller.reverse();
      }
    },
    onPanCancel: () {
      if (widget.enabled) {
        _controller.reverse();
      }
    },
    onPanEnd: (details) {
      if (widget.enabled) {
        _controller.reverse();
      }
    },
    child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
  );
}
