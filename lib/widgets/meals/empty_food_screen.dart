import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class EmptyFoodScreen extends StatelessWidget {
  final String message;

  const EmptyFoodScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      children: [
        SizedBox(
          height: 240,
          width: 240,
          child: ClipPath(
            clipper: LeftSideClipper(),
            child: Assets.images.empty.image(fit: BoxFit.fill),
          ),
        ),
        Strings.mealsAreNotAvailable
            .text(16, 20, 500)
            .c(context.colors.textStrong),
        message
            .text(14, 18, 400)
            .c(context.colors.textSub)
            .copyWith(textAlign: TextAlign.center),
      ],
    );
  }
}

class LeftSideClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    path.moveTo(5, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(5, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
