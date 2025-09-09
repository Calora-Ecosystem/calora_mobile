import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AvatarWithFlagWidget extends StatelessWidget {
  final String initials;
  final SvgPicture flagAsset;

  const AvatarWithFlagWidget({super.key, required this.initials, required this.flagAsset});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: context.colors.strokeSoft, width: 2),
            color: context.colors.accentWhite,
            shape: BoxShape.circle,
          ),
          child: initials.text(20, 24, 600).c(context.colors.accentSub),
        ),
        Positioned(bottom: -2, right: -2, child: flagAsset),
      ],
    );
  }
}
