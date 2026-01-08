import 'package:calora/domain/model/user/user_stat.dart';
import 'package:calora/widgets/builder/winner/winner_item_builder.dart';
import 'package:calora/widgets/leaderboard/leaderboard_widget.dart';
import 'package:calora/widgets/podium/podium_widget.dart';
import 'package:flutter/material.dart';

class LeaderboardSection extends StatelessWidget {
  const LeaderboardSection({
    required this.userStatesWithPlaceholders,
    required this.isGettingStats,
    required this.userStates,
  });

  final List<UserStatRequest> userStatesWithPlaceholders;
  final bool isGettingStats;
  final List<UserStatRequest> userStates;

  @override
  Widget build(BuildContext context) {
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
        LeaderboardWidget(users: userStates),
        const SizedBox(height: 24),
      ],
    );
  }
}
