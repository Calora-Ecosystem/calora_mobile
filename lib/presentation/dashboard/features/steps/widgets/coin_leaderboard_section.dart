import 'package:calora/common/di/injection.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/domain/model/user/user_stat.dart';
import 'package:calora/domain/repo/coins/coins_repo.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/avatar/flag/avatar_with_flag_widget.dart';
import 'package:calora/widgets/builder/winner/winner_item_builder.dart';
import 'package:calora/widgets/podium/podium_widget.dart';
import 'package:flutter/material.dart';

/// Loads the public coin ranking (`GET wallet/ranking`) and renders it with
/// [CoinLeaderboardSection]. A sliver, so it drops into the Steps tab's
/// scroll view in place of the step board.
class CoinLeaderboard extends StatefulWidget {
  const CoinLeaderboard({super.key});

  @override
  State<CoinLeaderboard> createState() => _CoinLeaderboardState();
}

class _CoinLeaderboardState extends State<CoinLeaderboard> {
  late final Future<List<UserStatRequest>> _ranking = getIt<CoinsRepo>()
      .getRanking();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserStatRequest>>(
      future: _ranking,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        return CoinLeaderboardSection(users: snapshot.data ?? const []);
      },
    );
  }
}

/// Public coin ranking for the Steps tab. Mirrors [LeaderboardSection] exactly
/// — same podium and row layout — but ranks by coins instead of steps, so the
/// two boards read as one family. Non-paginated: the coin board is a short
/// public list, not an infinite feed.
class CoinLeaderboardSection extends StatelessWidget {
  const CoinLeaderboardSection({super.key, required this.users});

  final List<UserStatRequest> users;

  @override
  Widget build(BuildContext context) {
    final topThree = List.generate(
      3,
      (index) => index < users.length
          ? users[index]
          : const UserStatRequest(
              firstName: '-',
              lastName: '',
              stepCount: 0,
              talks: 0,
            ),
    );

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: PodiumWidget(
            firstPosition: WinnerItemBuilder(
              userStat: topThree[0],
              loading: false,
            ),
            secondPosition: WinnerItemBuilder(
              userStat: topThree[1],
              loading: false,
            ),
            thirdPosition: WinnerItemBuilder(
              userStat: topThree[2],
              loading: false,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 2)),
        SliverList.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            if (index < 3) return const SizedBox.shrink();
            return Container(
              decoration: BoxDecoration(
                color: context.colors.white,
                borderRadius: index == 3
                    ? const BorderRadius.vertical(top: Radius.circular(12))
                    : null,
              ),
              child: _buildItem(context, users[index], index),
            );
          },
        ),
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: context.colors.white,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
            ),
            child: const SizedBox(height: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildItem(BuildContext context, UserStatRequest user, int index) {
    final colors = context.colors;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: (index + 1)
          .toString()
          .text(16, 20, 500)
          .c(colors.neutral900Primary),
      title: Row(
        children: [
          AvatarWithFlagWidget(
            initials: user.getInitials(),
            flagAsset: Assets.icons.circleFlag.svg(),
          ),
          const SizedBox(width: 8),
          user.isMe
              ? Strings.you.text(16, 20, 500).c(colors.neutral900Primary)
              : user.firstName.text(16, 20, 500).c(colors.neutral900Primary),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.monetization_on_rounded,
            size: 15,
            color: colors.accentSub,
          ),
          const SizedBox(width: 4),
          '${user.stepCount}'.text(12, 16, 600).c(colors.neutral900Primary),
        ],
      ),
    );
  }
}
