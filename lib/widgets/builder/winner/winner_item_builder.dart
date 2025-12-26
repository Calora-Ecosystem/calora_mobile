import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/loading/shimmer.dart';
import 'package:calora/domain/model/user/user_stat.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/avatar/flag/avatar_with_flag_widget.dart';
import 'package:flutter/material.dart';

class WinnerItemBuilder extends StatelessWidget {
  final UserStatRequest userStat;
  final bool loading;

  WinnerItemBuilder({super.key, required this.userStat, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 12),
        Stack(
          clipBehavior: Clip.none,
          children: [
            AvatarWithFlagWidget(
              initials: userStat.getInitials(),
              flagAsset: userStat.firstName == '-' ? null : Assets.icons.circleFlag.svg(),
              loading: loading,
            ),
            if (userStat.isWinner) Positioned(top: -10, right: -10, child: Assets.icons.crown.svg()),
          ],
        ),
        SizedBox(height: 8),
        ShimmerWrapper(
          loading: loading,
          shimmerChild: ShimmerChild(height: 20, width: 70, radius: 6),
          child: userStat.isMe
              ? Strings.you.text(16, 20, 500).c(context.colors.neutralPrimary)
              : userStat.firstName
                    .text(16, 20, 500)
                    .c(context.colors.neutral900Primary)
                    .copyWith(overflow: TextOverflow.ellipsis),
        ),
        SizedBox(height: 8),
        ShimmerWrapper(
          loading: loading,
          shimmerChild: const ShimmerChild(height: 32, width: 80, radius: 12),
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              color: context.colors.backgroundElevation6,
            ),
            child: userStat.prettySteps.text(12, 16, 500).c(context.colors.neutral900Primary),
          ),
        ),
      ],
    );
  }
}
