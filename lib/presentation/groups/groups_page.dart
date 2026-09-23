import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/bottom_sheet.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/common/widgets/snack_bar/custom_snack_bar.dart';
import 'package:calora/domain/model/group/step_group.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/groups/management/groups_management.dart';
import 'package:calora/presentation/groups/management/groups_manager.dart';
import 'package:calora/presentation/groups/widgets/group_action_sheets.dart';
import 'package:calora/widgets/app_bar/custom_app_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

@RoutePage()
class GroupsPage extends Managed<GroupsManager, GroupsState, GroupsEffect> {
  GroupsPage({super.key});

  /// Membership or steps may have changed in a group's detail — re-read.
  @override
  void onNavigateBack(GroupsManager manager) => manager.loadGroups();

  @override
  void listener(
    BuildContext context,
    GroupsManager manager,
    GroupsEffect effect,
  ) {
    effect.mapOrNull(
      created: (e) {
        CustomSnackBar.show(context, 'group_created'.tr());
        _openGroup(context, e.group);
      },
      joined: (e) {
        CustomSnackBar.show(context, 'group_joined'.tr());
        _openGroup(context, e.group);
      },
      joinFailed: (_) => CustomSnackBar.show(context, 'join_failed'.tr()),
      deleted: (_) => CustomSnackBar.show(context, 'group_deleted'.tr()),
      left: (_) => CustomSnackBar.show(context, 'group_left'.tr()),
      failed: (_) => CustomSnackBar.show(context, 'something_went_wrong'.tr()),
    );
  }

  @override
  Widget builder(
    BuildContext context,
    GroupsManager manager,
    GroupsState state,
  ) {
    return Scaffold(
      backgroundColor: context.colors.softGray,
      appBar: CustomAppBar(
        title: 'groups_title'.tr(),
        onBack: () => context.router.maybePop(),
      ),
      body: state.loading && state.groups.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.groups.isEmpty
          ? _buildEmpty(context, manager)
          : _buildList(context, manager, state),
    );
  }

  Widget _buildList(
    BuildContext context,
    GroupsManager manager,
    GroupsState state,
  ) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            itemCount: state.groups.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final group = state.groups[index];
              return Dismissible(
                key: ValueKey(group.id),
                direction: DismissDirection.endToStart,
                background: _dismissBackground(context, group),
                confirmDismiss: (_) => _confirmRemove(context, group),
                onDismissed: (_) => manager.removeGroup(group),
                child: _GroupCard(
                  group: group,
                  onTap: () => _openGroup(context, group),
                  onLongPress: () async {
                    if (await _confirmRemove(context, group) == true) {
                      manager.removeGroup(group);
                    }
                  },
                ),
              );
            },
          ),
        ),
        _buildActions(context, manager),
      ],
    );
  }

  /// Red swipe affordance behind a group card. Its label matches what the swipe
  /// will do — delete for admins, leave for members.
  Widget _dismissBackground(BuildContext context, StepGroup group) {
    final colors = context.colors;
    final isAdmin = group.isOwner;
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: colors.errorLighter,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAdmin ? Icons.delete_outline_rounded : Icons.logout_rounded,
            color: colors.errorBase,
            size: 20,
          ),
          const SizedBox(width: 6),
          (isAdmin ? 'group_delete' : 'group_leave')
              .tr()
              .text(13, 16, 600)
              .c(colors.errorBase),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, GroupsManager manager) {
    final colors = context.colors;
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 72,
                  width: 72,
                  decoration: BoxDecoration(
                    color: colors.lightGreen,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.groups_rounded,
                    color: colors.accentSub,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                'no_groups_title'
                    .tr()
                    .text(18, 24, 600)
                    .c(colors.textStrong)
                    .copyWith(textAlign: TextAlign.center),
                const SizedBox(height: 8),
                'no_groups_desc'
                    .tr()
                    .text(14, 20, 400)
                    .c(colors.textSub)
                    .copyWith(textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
        _buildActions(context, manager),
      ],
    );
  }

  Widget _buildActions(BuildContext context, GroupsManager manager) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Row(
          children: [
            Expanded(
              child: _actionButton(
                context,
                icon: Icons.add_rounded,
                label: 'create_group'.tr(),
                filled: true,
                onTap: () => _showCreateSheet(context, manager),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _actionButton(
                context,
                icon: Icons.login_rounded,
                label: 'join_by_code'.tr(),
                filled: false,
                onTap: () => _showJoinSheet(context, manager),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Filled = primary accent; outlined = white with an accent border so it still
  /// reads clearly as a button on the grey background.
  Widget _actionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? colors.accentSub : colors.white,
          borderRadius: BorderRadius.circular(14),
          border: filled
              ? null
              : Border.all(color: colors.accentSub, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: filled ? colors.textWhite : colors.accentSub,
            ),
            const SizedBox(width: 8),
            label
                .text(14, 18, 600)
                .c(filled ? colors.textWhite : colors.accentSub),
          ],
        ),
      ),
    );
  }

  /// Confirms delete (admin) or leave (member). Returns true when confirmed.
  Future<bool?> _confirmRemove(BuildContext context, StepGroup group) {
    final colors = context.colors;
    final isAdmin = group.isOwner;
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.white,
        title: (isAdmin ? 'group_delete' : 'group_leave')
            .tr()
            .text(17, 22, 600)
            .c(colors.textStrong),
        content: (isAdmin ? 'group_delete_confirm' : 'group_leave_confirm')
            .tr(namedArgs: {'name': group.name})
            .text(14, 20, 400)
            .c(colors.textSub),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Strings.close.text(14, 18, 500).c(colors.textSub),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: (isAdmin ? 'group_delete' : 'group_leave')
                .tr()
                .text(14, 18, 600)
                .c(colors.errorBase),
          ),
        ],
      ),
    );
  }

  void _showCreateSheet(BuildContext context, GroupsManager manager) {
    context.showAppBottomSheet(
      child: CreateGroupSheet(onCreate: manager.createGroup),
    );
  }

  void _showJoinSheet(BuildContext context, GroupsManager manager) {
    context.showAppBottomSheet(
      child: JoinGroupSheet(onJoin: manager.joinByCode),
    );
  }

  void _openGroup(BuildContext context, StepGroup group) {
    context.router.push(GroupDetailRoute(groupId: group.id));
  }
}

/// One group row: name, member count, and the group's combined steps.
class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.onTap,
    required this.onLongPress,
  });

  final StepGroup group;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: colors.lightGreen,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.groups_rounded,
                color: colors.accentSub,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  group.name.text(15, 20, 600).c(colors.textStrong),
                  const SizedBox(height: 2),
                  'group_members'
                      .tr(namedArgs: {'count': '${group.memberCount}'})
                      .text(12, 16, 400)
                      .c(colors.textSub),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                '${group.totalSteps}'.text(15, 18, 700).c(colors.accentSub),
                const SizedBox(height: 2),
                'group_total_steps'.tr().text(11, 14, 400).c(colors.textSub),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
