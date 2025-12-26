import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/domain/model/user/user_stat.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/avatar/flag/avatar_with_flag_widget.dart';
import 'package:flutter/material.dart';

class LeaderboardWidget extends StatelessWidget {
  final List<UserStatRequest> users;

  const LeaderboardWidget({super.key, required this.users});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: context.colors.white, borderRadius: BorderRadius.circular(12)),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: NeverScrollableScrollPhysics(),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 24),
                leading: (index + 4).toString().text(16, 20, 500).c(context.colors.neutralPrimary),
                title: Row(
                  children: [
                    AvatarWithFlagWidget(
                      initials: user.getInitials(),
                      flagAsset: Assets.icons.circleFlag.svg(),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        user.isMe
                            ? Strings.you.text(16, 20, 500).c(context.colors.neutralPrimary)
                            : user.firstName.text(16, 20, 500).c(context.colors.neutralPrimary),
                        const SizedBox(height: 8),
                        ('${user.prettyTalks} talks').text(12, 16, 500).c(context.colors.textSub),
                      ],
                    ),
                  ],
                ),
                trailing: user.prettySteps.text(12, 16, 500).c(context.colors.neutralPrimary),
              ),
            ],
          );
        },
      ),
    );
  }
}
