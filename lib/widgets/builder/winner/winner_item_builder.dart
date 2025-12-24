import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/domain/model/user/user_stat.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/avatar/flag/avatar_with_flag_widget.dart';
import 'package:flutter/material.dart';

class WinnerItemBuilder extends StatelessWidget {
  final UserStatRequest userStat;

  WinnerItemBuilder({super.key, required this.userStat});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 12),
        Stack(
          clipBehavior: Clip.none,
          children: [
            AvatarWithFlagWidget(initials: userStat.getInitials(), flagAsset: Assets.icons.circleFlag.svg()),
            if (userStat.isWinner) Positioned(top: -8, right: -7, child: Assets.icons.crown.svg()),
          ],
        ),
        SizedBox(height: 8),
        userStat.isMe
            ? Strings.you.text(16, 20, 500).c(context.colors.neutralPrimary)
            : userStat.firstName
                  .text(16, 20, 500)
                  .c(context.colors.neutral900Primary)
                  .copyWith(overflow: TextOverflow.ellipsis),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            color: context.colors.backgroundElevation6,
          ),
          child: userStat.prettySteps.text(12, 16, 500).c(context.colors.neutral900Primary),
        ),
      ],
    );
  }
}
