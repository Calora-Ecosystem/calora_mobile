import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/domain/model/user/user_stat.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/avatar/flag/avatar_with_flag_widget.dart';
import 'package:flutter/material.dart';

class WinnerItemBuilder extends StatelessWidget {
  final UserStat userStat;

  WinnerItemBuilder({super.key, required this.userStat});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [
        AvatarWithFlagWidget(
          initials: userStat.getInitials(),
          flagAsset: Assets.icons.circleFlag.svg(),
        ),
        SizedBox(height: 8),
        Flexible(
          child: userStat.firstName
              .text(16, 20, 500)
              .c(context.colors.neutral900Primary),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            color: context.colors.backgroundElevation6,
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: userStat.prettySteps
                .text(12, 16, 500)
                .c(context.colors.neutral900Primary),
          ),
        ),
      ],
    );
  }
}
