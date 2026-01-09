import 'package:calora/domain/model/user/user_stat.dart';
import 'package:calora/widgets/builder/winner/winner_item_builder.dart';
import 'package:calora/widgets/leaderboard/leaderboard_widget.dart';
import 'package:calora/widgets/podium/podium_widget.dart';
import 'package:flutter/material.dart';

class LeaderboardSection extends StatelessWidget {
  const LeaderboardSection({
    super.key,
    required this.allUserStatsForPeriod,
    required this.isGettingStats,
  });

  final List<UserStatRequest> allUserStatsForPeriod;
  final bool isGettingStats;

  @override
  Widget build(BuildContext context) {
    final List<UserStatRequest> userStatesWithPlaceholders = List.generate(
      3,
      (index) => index < allUserStatsForPeriod.length
          ? allUserStatsForPeriod[index]
          : const UserStatRequest(
              firstName: '-',
              lastName: '',
              stepCount: 0,
              talks: 0,
            ),
    );

    final List<UserStatRequest> leaderboardUsers =
        allUserStatsForPeriod.length > 3 ? allUserStatsForPeriod.sublist(3) : [];

    return Column(
      children: [
        PodiumWidget(
          firstPosition: WinnerItemBuilder(
            userStat: userStatesWithPlaceholders[0],
            loading: isGettingStats,
          ),
          secondPosition: WinnerItemBuilder(
            userStat: userStatesWithPlaceholders[1],
            loading: isGettingStats,
          ),
          thirdPosition: WinnerItemBuilder(
            userStat: userStatesWithPlaceholders[2],
            loading: isGettingStats,
          ),
        ),
        const SizedBox(height: 2),
        LeaderboardWidget(users: leaderboardUsers),
        const SizedBox(height: 24),
      ],
    );
  }
}
