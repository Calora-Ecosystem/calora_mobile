import 'dart:async';

import 'package:calora/domain/model/group/step_group.dart';
import 'package:calora/domain/repo/group/group_repo.dart';
import 'package:calora/presentation/groups/management/groups_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

/// Backs the groups list, a group's detail and the create/join flows against
/// the `step-groups` API. The list holds summaries; [loadDetail] swaps a group
/// for its full version (ranked members) when its detail page opens.
@injectable
class GroupsManager extends Manager<GroupsState, GroupsEffect> {
  final GroupRepo _repo;

  GroupsManager(this._repo) : super(const GroupsState());

  @override
  void initialize() {
    loadGroups();
  }

  Future<void> loadGroups() async {
    try {
      final groups = await _repo.getGroups();
      if (isClosed) return;
      // Keep already-loaded members so an open detail doesn't flash empty.
      final merged = groups.map((g) {
        final known = state.groups.where((k) => k.id == g.id).firstOrNull;
        return known == null || known.members.isEmpty
            ? g
            : StepGroup(
                id: g.id,
                name: g.name,
                inviteCode: g.inviteCode,
                isOwner: g.isOwner,
                memberCount: g.memberCount,
                totalSteps: g.totalSteps,
                members: known.members,
              );
      }).toList();
      emit(state.copyWith(groups: merged, loading: false));
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(loading: false));
      publish(const GroupsEffect.failed());
    }
  }

  /// Fetches one group with its ranked members.
  Future<void> loadDetail(String groupId) async {
    try {
      final group = await _repo.getGroup(groupId);
      if (isClosed) return;
      _upsert(group);
    } catch (_) {
      if (isClosed) return;
      // Not a member any more (removed / group deleted) — drop it.
      emit(
        state.copyWith(
          groups: state.groups.where((g) => g.id != groupId).toList(),
          loading: false,
        ),
      );
    }
  }

  void _upsert(StepGroup group) {
    final groups = [...state.groups];
    final index = groups.indexWhere((g) => g.id == group.id);
    if (index == -1) {
      groups.insert(0, group);
    } else {
      groups[index] = group;
    }
    emit(state.copyWith(groups: groups, loading: false));
  }

  Future<void> createGroup(String name) async {
    try {
      final group = await _repo.createGroup(name.trim());
      if (isClosed) return;
      _upsert(group);
      publish(GroupsEffect.created(group));
    } catch (_) {
      publish(const GroupsEffect.failed());
    }
  }

  Future<void> joinByCode(String code) async {
    if (code.trim().isEmpty) {
      publish(const GroupsEffect.joinFailed());
      return;
    }
    try {
      final group = await _repo.joinByCode(code.trim());
      if (isClosed) return;
      _upsert(group);
      publish(GroupsEffect.joined(group));
    } catch (_) {
      publish(const GroupsEffect.joinFailed());
    }
  }

  /// Admin-only: removes a member from the group.
  Future<void> removeMember(String groupId, GroupMember member) async {
    try {
      await _repo.removeMember(groupId, member.userId);
      publish(const GroupsEffect.memberRemoved());
      await loadDetail(groupId);
    } catch (_) {
      publish(const GroupsEffect.failed());
    }
  }

  /// Admins delete the group; everyone else just leaves it.
  Future<void> removeGroup(StepGroup group) async {
    // Optimistic: the card is already swiped away.
    emit(
      state.copyWith(
        groups: state.groups.where((g) => g.id != group.id).toList(),
      ),
    );
    try {
      if (group.isOwner) {
        await _repo.deleteGroup(group.id);
        publish(const GroupsEffect.deleted());
      } else {
        await _repo.leaveGroup(group.id);
        publish(const GroupsEffect.left());
      }
    } catch (_) {
      publish(const GroupsEffect.failed());
    }
    unawaited(loadGroups());
  }
}
