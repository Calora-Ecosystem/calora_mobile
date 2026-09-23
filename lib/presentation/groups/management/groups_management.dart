import 'package:calora/domain/model/group/step_group.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'groups_management.freezed.dart';

@freezed
abstract class GroupsState with _$GroupsState {
  const factory GroupsState({
    @Default(true) bool loading,
    @Default([]) List<StepGroup> groups,
  }) = _GroupsState;
}

@freezed
class GroupsEffect with _$GroupsEffect {
  const factory GroupsEffect.created(StepGroup group) = GroupCreated;

  const factory GroupsEffect.joined(StepGroup group) = GroupJoined;

  const factory GroupsEffect.joinFailed() = GroupJoinFailed;

  const factory GroupsEffect.memberRemoved() = GroupMemberRemoved;

  const factory GroupsEffect.deleted() = GroupDeleted;

  const factory GroupsEffect.left() = GroupLeft;

  const factory GroupsEffect.failed() = GroupFailed;
}
