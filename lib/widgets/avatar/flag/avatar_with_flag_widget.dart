import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/widgets/loading/shimmer.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AvatarWithFlagWidget extends StatelessWidget {
  final String initials;
  final SvgPicture flagAsset;
  final bool loading;

  const AvatarWithFlagWidget({super.key, required this.initials, required this.flagAsset, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ShimmerWrapper(
          loading: loading,
          shimmerChild: ShimmerChild(height: 48, width: 48, radius: 100, border: _border(context)),
          child: Container(
            height: 48,
            width: 48,
            padding: EdgeInsets.zero,
            decoration: BoxDecoration(
              border: _border(context),
              color: context.colors.accentWhite,
              shape: BoxShape.circle,
            ),
            child: Center(child: initials.text(20, 24, 600).c(context.colors.accentSub)),
          ),
        ),
        Positioned(
          bottom: -2,
          right: -2,
          child: ShimmerWrapper(
            loading: loading,
            shimmerChild: ShimmerChild(height: 20, width: 20, radius: 100),
            child: flagAsset,
          ),
        ),
      ],
    );
  }

  BoxBorder _border(BuildContext context) => Border.all(color: context.colors.strokeSoft, width: 2);
}
