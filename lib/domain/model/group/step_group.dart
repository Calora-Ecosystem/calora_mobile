import 'package:calora/domain/model/user/user_stat.dart';

/// A member of a step group. Kept separate from [UserStatRequest] (the API
/// leaderboard model) but maps to it via [toUserStat] so the group ranking can
/// reuse the same podium / leaderboard widgets as the global board.
class GroupMember {
  final int userId;
  final String firstName;
  final String lastName;
  final int stepCount;
  final bool isMe;
  final bool isOwner;

  const GroupMember({
    this.userId = 0,
    required this.firstName,
    required this.lastName,
    required this.stepCount,
    this.isMe = false,
    this.isOwner = false,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) => GroupMember(
    userId: (json['userId'] as num?)?.toInt() ?? 0,
    firstName: json['name'] as String? ?? '',
    lastName: '',
    stepCount: (json['steps'] as num?)?.round() ?? 0,
    isMe: json['isMe'] as bool? ?? false,
    isOwner: json['isOwner'] as bool? ?? false,
  );

  UserStatRequest toUserStat() => UserStatRequest(
    firstName: firstName,
    lastName: lastName,
    stepCount: stepCount,
    talks: 0,
    isMe: isMe,
  );
}

/// A private step group the user created or joined (`GET step-groups`).
/// The list endpoint returns summaries with no [members]; the detail endpoint
/// (`GET step-groups/{id}`) fills them in, already ranked by steps.
class StepGroup {
  final String id;
  final String name;
  final String inviteCode;

  /// Whether the current user is the group's admin.
  final bool isOwner;
  final int memberCount;

  /// The group's combined steps for the selected period (today by default).
  final int totalSteps;
  final List<GroupMember> members;

  const StepGroup({
    required this.id,
    required this.name,
    required this.inviteCode,
    this.isOwner = false,
    this.memberCount = 0,
    this.totalSteps = 0,
    this.members = const [],
  });

  factory StepGroup.fromJson(Map<String, dynamic> json) {
    final members = (json['members'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(GroupMember.fromJson)
        .toList();
    return StepGroup(
      id: '${json['id'] ?? ''}',
      name: json['name'] as String? ?? '',
      inviteCode: json['inviteCode'] as String? ?? '',
      isOwner: json['isOwner'] as bool? ?? false,
      memberCount: (json['memberCount'] as num?)?.toInt() ?? members.length,
      totalSteps: (json['totalSteps'] as num?)?.round() ?? 0,
      members: members,
    );
  }

  /// Members ordered by step count, highest first — the ranking order.
  List<GroupMember> get ranked =>
      [...members]..sort((a, b) => b.stepCount.compareTo(a.stepCount));
}
