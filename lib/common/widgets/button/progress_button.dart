import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class ProgressButton extends StatelessWidget {
  final double progress;
  final Duration step;
  final bool isPaused;
  final VoidCallback onToggle;

  const ProgressButton({
    super.key,
    required this.progress,
    required this.step,
    required this.isPaused,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: context.colors.backgroundElevation,
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: step,
              builder: (context, value, child) => Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(widthFactor: value, child: child),
              ),
              child: Container(color: context.colors.accentSub),
            ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  isPaused
                      ? Assets.icons.start.svg(color: context.colors.black)
                      : Assets.icons.pause.svg(),
                  const SizedBox(width: 8),
                  (isPaused ? Strings.resume : Strings.pause)
                      .text(16, 20, 500)
                      .c(context.colors.textStrong),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
