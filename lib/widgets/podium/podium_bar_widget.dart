import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class PodiumBarWidget extends StatelessWidget {
  const PodiumBarWidget({
    super.key,
    required this.title,
    required this.width,
    required this.rankingText,
    required this.height,
  });

  final Widget title;
  final double width;
  final String rankingText;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: width,
          child: Center(child: title),
        ),
        const SizedBox(height: 10),
        RotatedBox(
          quarterTurns: 2,
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.02)
              ..rotateX(3.14 / 10),
            alignment: FractionalOffset.center,
            child: Container(
                height: 10,
                width: width - 3,
                decoration: BoxDecoration(color: context.colors.accentDisabled)
            ),
          ),
        ),
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(gradient: LinearGradient(
          colors: [
    context.colors.accentLightSub,
    context.colors.accentGreenWhite
    ], begin: Alignment.topCenter,
    end: Alignment.bottomCenter,)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RotatedBox(
                quarterTurns: 0,
                child: rankingText
                    .text(24, 32, 700)
                    .c(context.colors.textWhite),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
