import 'dart:developer';

import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/service/pagination_service.dart';
import 'package:calora/domain/model/user/user_stat.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/avatar/flag/avatar_with_flag_widget.dart';
import 'package:calora/widgets/builder/winner/winner_item_builder.dart';
import 'package:calora/widgets/podium/podium_widget.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class LeaderboardSection extends StatelessWidget {
  final PaginationService<UserStatRequest> paginationService;

  const LeaderboardSection({super.key, required this.paginationService});

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        ValueListenableBuilder<PagingState<int, UserStatRequest>>(
          valueListenable: paginationService.pagingController,
          builder: (context, pagingState, child) {
            final allUsers = pagingState.itemList ?? [];
            final bool isLoadingFirstPage = pagingState.status == PagingStatus.loadingFirstPage;

            final List<UserStatRequest> topThree = List.generate(
              3,
              (index) => index < allUsers.length
                  ? allUsers[index]
                  : const UserStatRequest(firstName: '-', lastName: '', stepCount: 0, talks: 0),
            );

            return SliverToBoxAdapter(
              child: PodiumWidget(
                firstPosition: WinnerItemBuilder(userStat: topThree[0], loading: isLoadingFirstPage),
                secondPosition: WinnerItemBuilder(userStat: topThree[1], loading: isLoadingFirstPage),
                thirdPosition: WinnerItemBuilder(userStat: topThree[2], loading: isLoadingFirstPage),
              ),
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 2)),
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(color: context.colors.white, borderRadius: BorderRadius.circular(12)),
          ),
        ),
        PagedSliverList<int, UserStatRequest>(
          pagingController: paginationService.pagingController,
          builderDelegate: PagedChildBuilderDelegate<UserStatRequest>(
            itemBuilder: (context, user, index) {
              log('PagedSliverList: Building item at index $index', name: 'LeaderboardSection');

              if (index < 3) return const SizedBox.shrink();

              return Container(
                decoration: BoxDecoration(
                  color: context.colors.white,
                  borderRadius: index == 3 ? BorderRadius.vertical(top: Radius.circular(12)) : null,
                ),
                child: _buildLeaderboardItem(context, user, index),
              );
            },
            firstPageProgressIndicatorBuilder: (context) => const SizedBox.shrink(),
            newPageProgressIndicatorBuilder: (context) => Container(
              color: context.colors.white,
              padding: const EdgeInsets.all(16.0),
              child: const Center(child: CircularProgressIndicator.adaptive()),
            ),
            newPageErrorIndicatorBuilder: (context) => Container(
              color: context.colors.white,
              padding: const EdgeInsets.all(16.0),
              child: Strings.somethingWentWrong.text(14, 16, 500),
            ),
            noMoreItemsIndicatorBuilder: (context) => Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: context.colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: const SizedBox(height: 10),
            ),
            firstPageErrorIndicatorBuilder: (context) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Strings.somethingWentWrong.text(14, 16, 500),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardItem(BuildContext context, UserStatRequest user, int index) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: (index + 1).toString().text(16, 20, 500).c(context.colors.neutral900Primary),
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
                  ? Strings.you.text(16, 20, 500).c(context.colors.neutral900Primary)
                  : user.firstName.text(16, 20, 500).c(context.colors.neutral900Primary),
            ],
          ),
        ],
      ),
      trailing: user.prettySteps.text(12, 16, 500).c(context.colors.neutral900Primary),
    );
  }
}
