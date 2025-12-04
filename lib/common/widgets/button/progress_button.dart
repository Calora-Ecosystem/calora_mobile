import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class ProgressButton extends StatefulWidget {
  final Duration duration;
  final VoidCallback onFinished;

  const ProgressButton({super.key, required this.duration, required this.onFinished});

  @override
  State<ProgressButton> createState() => _ProgressButtonState();
}

class _ProgressButtonState extends State<ProgressButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addListener(() => setState(() {}));
  }

  void _toggle() {
    if (_controller.isCompleted) {
      widget.onFinished();
    } else if (_controller.isAnimating) {
      _controller.stop();
    } else {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _controller.value;

    return GestureDetector(
      onTap: _toggle,
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
              child: progress < 1.0
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Assets.icons.pause.svg(),
                        const SizedBox(width: 8),
                        'Pause'.text(16, 20, 500).c(context.colors.textStrong),
                      ],
                    )
                  : Strings.finish
                        .text(16, 20, 500)
                        .c(context.colors.textWhite)
                        .copyWith(textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
