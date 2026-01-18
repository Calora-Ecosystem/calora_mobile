import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class ProgressButton extends StatefulWidget {
  final Duration duration;
  final bool isPaused;
  final VoidCallback onToggle;
  final VoidCallback onFinished;

  const ProgressButton({
    super.key,
    required this.duration,
    required this.isPaused,
    required this.onToggle,
    required this.onFinished,
  });

  @override
  State<ProgressButton> createState() => _ProgressButtonState();
}

class _ProgressButtonState extends State<ProgressButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(
          vsync: this,
          duration: widget.duration,
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            widget.onFinished();
          }
        });
  }

  @override
  void didUpdateWidget(covariant ProgressButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isPaused) {
      _controller.stop();
    } else if (!_controller.isAnimating && !_controller.isCompleted) {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        return GestureDetector(
          onTap: widget.onToggle,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: context.colors.backgroundElevation,
            ),
            clipBehavior: Clip.hardEdge,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(color: context.colors.accentSub),
                  ),
                ),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      widget.isPaused ? Assets.icons.start.svg(color: context.colors.black) : Assets.icons.pause.svg(),
                      const SizedBox(width: 8),
                      (widget.isPaused ? 'Resume' : 'Pause').text(16, 20, 500).c(context.colors.textStrong),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
