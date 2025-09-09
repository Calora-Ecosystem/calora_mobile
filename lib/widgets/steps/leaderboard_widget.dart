import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/domain/model/steps/leaderboard.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/steps/avatar_with_flag_widget.dart';
import 'package:flutter/material.dart';

class LeaderboardWidget extends StatelessWidget {
  final List<UserStat> users;

  const LeaderboardWidget({super.key, required this.users});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];

          return Column(
            children: [
              ListTile(
                leading: (index + 4).toString().text(16, 20, 500).c(context.colors.neutralPrimary),
                title: Row(
                  children: [
                    AvatarWithFlagWidget(initials: 'EH', flagAsset: Assets.icons.circleFlag.svg()),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        users[index].name.text(16, 20, 500).c(context.colors.neutralPrimary),
                        const SizedBox(height: 8),
                        (users[index].talks.toString() + ' talks')
                            .text(12, 16, 500)
                            .c(context.colors.textSub),
                      ],
                    ),
                  ],
                ),
                trailing: user.scoreText.text(12, 16, 500).c(context.colors.neutralPrimary),
              ),
            ],
          );
        },
      ),
    );
  }
}
