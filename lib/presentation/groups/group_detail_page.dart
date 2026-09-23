import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/snack_bar/custom_snack_bar.dart';
import 'package:calora/domain/model/group/step_group.dart';
import 'package:calora/domain/model/user/user_stat.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/groups/management/groups_management.dart';
import 'package:calora/presentation/groups/management/groups_manager.dart';
import 'package:calora/widgets/app_bar/custom_app_bar.dart';
import 'package:calora/widgets/avatar/flag/avatar_with_flag_widget.dart';
import 'package:calora/widgets/builder/winner/winner_item_builder.dart';
import 'package:calora/widgets/podium/podium_widget.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';
import 'package:share_plus/share_plus.dart';

@RoutePage()
class GroupDetailPage
    extends Managed<GroupsManager, GroupsState, GroupsEffect> {
  GroupDetailPage({super.key, required this.groupId});

  final String groupId;

  @override
  void init(BuildContext context, GroupsManager manager) {
    manager.loadDetail(groupId);
  }

  @override
  void listener(
    BuildContext context,
    GroupsManager manager,
    GroupsEffect effect,
  ) {
    effect.mapOrNull(
      memberRemoved: (_) => CustomSnackBar.show(context, 'member_removed'.tr()),
      failed: (_) => CustomSnackBar.show(context, 'something_went_wrong'.tr()),
    );
  }

  @override
  Widget builder(
    BuildContext context,
    GroupsManager manager,
    GroupsState state,
  ) {
    final group = state.groups.firstWhereOrNull((g) => g.id == groupId);
    if (group == null) {
      return Scaffold(
        backgroundColor: context.colors.softGray,
        appBar: CustomAppBar(
          title: 'groups_title'.tr(),
          onBack: () => context.router.maybePop(),
        ),
      );
    }

    final ranked = group.ranked;
    final isAdmin = group.isOwner;

    return Scaffold(
      backgroundColor: context.colors.softGray,
      appBar: CustomAppBar(
        title: group.name,
        onBack: () => context.router.maybePop(),
        trailing: GestureDetector(
          onTap: () => _shareInvite(group),
          child: Assets.icons.share.svg(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _buildInviteCard(context, group),
          const SizedBox(height: 16),
          PodiumWidget(
            firstPosition: WinnerItemBuilder(
              userStat: _atOrPlaceholder(ranked, 0),
              loading: false,
            ),
            secondPosition: WinnerItemBuilder(
              userStat: _atOrPlaceholder(ranked, 1),
              loading: false,
            ),
            thirdPosition: WinnerItemBuilder(
              userStat: _atOrPlaceholder(ranked, 2),
              loading: false,
            ),
          ),
          const SizedBox(height: 12),
          _buildRankList(context, ranked),
          if (isAdmin) ...[
            const SizedBox(height: 24),
            'members_manage'
                .tr()
                .text(16, 20, 600)
                .c(context.colors.textStrong),
            const SizedBox(height: 8),
            _buildManageList(context, manager, group),
          ],
        ],
      ),
    );
  }

  Widget _buildInviteCard(BuildContext context, StepGroup group) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              'invite_code'.tr().text(12, 16, 400).c(colors.textSub),
              const SizedBox(height: 2),
              group.inviteCode.text(18, 22, 700).c(colors.textStrong),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _shareInvite(group),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: colors.accentSub,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.share_rounded, size: 15, color: colors.textWhite),
                  const SizedBox(width: 6),
                  'invite_friends'.tr().text(13, 16, 600).c(colors.textWhite),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Members ranked 4th and below — the same row layout as the global board.
  Widget _buildRankList(BuildContext context, List<GroupMember> ranked) {
    if (ranked.length <= 3) return const SizedBox.shrink();
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (int i = 3; i < ranked.length; i++)
            _buildRankItem(context, ranked[i], i),
        ],
      ),
    );
  }

  Widget _buildRankItem(BuildContext context, GroupMember member, int index) {
    final colors = context.colors;
    final stat = member.toUserStat();
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: (index + 1)
          .toString()
          .text(16, 20, 500)
          .c(colors.neutral900Primary),
      title: Row(
        children: [
          AvatarWithFlagWidget(
            initials: stat.getInitials(),
            flagAsset: Assets.icons.circleFlag.svg(),
          ),
          const SizedBox(width: 8),
          member.isMe
              ? Strings.you.text(16, 20, 500).c(colors.neutral900Primary)
              : member.firstName.text(16, 20, 500).c(colors.neutral900Primary),
        ],
      ),
      trailing: stat.prettySteps.text(12, 16, 500).c(colors.neutral900Primary),
    );
  }

  /// Admin-only list where every member (except the owner) can be removed.
  Widget _buildManageList(
    BuildContext context,
    GroupsManager manager,
    StepGroup group,
  ) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (final member in group.members)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: AvatarWithFlagWidget(
                initials: member.toUserStat().getInitials(),
                flagAsset: Assets.icons.circleFlag.svg(),
              ),
              title: (member.isMe ? Strings.you : member.firstName)
                  .text(15, 20, 500)
                  .c(colors.neutral900Primary),
              subtitle: member.isOwner
                  ? 'group_admin'.tr().text(12, 16, 400).c(colors.textSub)
                  : null,
              trailing: member.isOwner
                  ? null
                  : GestureDetector(
                      onTap: () =>
                          _confirmRemove(context, manager, group.id, member),
                      child: Icon(
                        Icons.remove_circle_outline_rounded,
                        color: colors.errorBase,
                        size: 22,
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  void _confirmRemove(
    BuildContext context,
    GroupsManager manager,
    String groupId,
    GroupMember member,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.colors.white,
        title: 'remove_member'
            .tr()
            .text(17, 22, 600)
            .c(context.colors.textStrong),
        content: 'remove_member_confirm'
            .tr(namedArgs: {'name': member.firstName})
            .text(14, 20, 400)
            .c(context.colors.textSub),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Strings.close.text(14, 18, 500).c(context.colors.textSub),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              manager.removeMember(groupId, member);
            },
            child: 'remove_member'
                .tr()
                .text(14, 18, 600)
                .c(context.colors.errorBase),
          ),
        ],
      ),
    );
  }

  UserStatRequest _atOrPlaceholder(List<GroupMember> ranked, int index) {
    if (index < ranked.length) return ranked[index].toUserStat();
    return const UserStatRequest(
      firstName: '-',
      lastName: '',
      stepCount: 0,
      talks: 0,
    );
  }

  void _shareInvite(StepGroup group) {
    SharePlus.instance.share(
      ShareParams(
        text: 'share_invite'.tr(namedArgs: {'code': group.inviteCode}),
      ),
    );
  }
}
