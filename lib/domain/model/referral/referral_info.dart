/// The user's referral dashboard (`GET referrals/me`).
///
/// Every [friendsGoal] friends who join with the user's code and finish
/// onboarding earn [premiumDays] days of Premium. A user who joined with a
/// friend's code gets [discountPercent]% off their first Premium purchase.
class ReferralInfo {
  final String code;

  /// Friends who confirmed the code at sign-up.
  final int invited;

  /// Friends who finished onboarding — these count toward Premium.
  final int active;
  final int friendsGoal;
  final int premiumDays;

  /// Active friends in the current round (0..friendsGoal-1).
  final int progressFriends;
  final int friendsLeft;
  final double progress;
  final int premiumsEarned;

  final bool isReferred;
  final String? referredBy;

  /// The user can still enter a friend's code (new account, none entered yet).
  final bool canApplyCode;
  final int discountPercent;

  /// The referral discount is still unused.
  final bool hasDiscount;

  const ReferralInfo({
    this.code = '',
    this.invited = 0,
    this.active = 0,
    this.friendsGoal = 5,
    this.premiumDays = 30,
    this.progressFriends = 0,
    this.friendsLeft = 5,
    this.progress = 0,
    this.premiumsEarned = 0,
    this.isReferred = false,
    this.referredBy,
    this.canApplyCode = false,
    this.discountPercent = 10,
    this.hasDiscount = false,
  });

  factory ReferralInfo.fromJson(Map<String, dynamic> json) => ReferralInfo(
    code: json['code'] as String? ?? '',
    invited: (json['invited'] as num?)?.toInt() ?? 0,
    active: (json['active'] as num?)?.toInt() ?? 0,
    friendsGoal: (json['friendsGoal'] as num?)?.toInt() ?? 5,
    premiumDays: (json['premiumDays'] as num?)?.toInt() ?? 30,
    progressFriends: (json['progressFriends'] as num?)?.toInt() ?? 0,
    friendsLeft: (json['friendsLeft'] as num?)?.toInt() ?? 5,
    progress: (json['progress'] as num?)?.toDouble() ?? 0,
    premiumsEarned: (json['premiumsEarned'] as num?)?.toInt() ?? 0,
    isReferred: json['isReferred'] as bool? ?? false,
    referredBy: json['referredBy'] as String?,
    canApplyCode: json['canApplyCode'] as bool? ?? false,
    discountPercent: (json['discountPercent'] as num?)?.toInt() ?? 10,
    hasDiscount: json['hasDiscount'] as bool? ?? false,
  );
}

/// Status of an invited friend: signed up with the code, or fully in the app.
enum ReferredFriendStatus { joined, active }

/// A friend who joined with the user's code (`GET referrals/invited`).
class ReferredFriend {
  final int userId;
  final String name;
  final String? photo;
  final ReferredFriendStatus status;
  final DateTime joinedAt;
  final DateTime? activatedAt;

  const ReferredFriend({
    required this.userId,
    required this.name,
    this.photo,
    required this.status,
    required this.joinedAt,
    this.activatedAt,
  });

  factory ReferredFriend.fromJson(Map<String, dynamic> json) => ReferredFriend(
    userId: (json['userId'] as num?)?.toInt() ?? 0,
    name: json['name'] as String? ?? '',
    photo: json['photo'] as String?,
    status: (json['status'] as String?)?.toLowerCase() == 'active'
        ? ReferredFriendStatus.active
        : ReferredFriendStatus.joined,
    joinedAt:
        DateTime.tryParse(json['joinedAt'] as String? ?? '') ?? DateTime.now(),
    activatedAt: DateTime.tryParse(json['activatedAt'] as String? ?? ''),
  );
}

/// Result of confirming a friend's code (`POST referrals/apply`).
class ApplyReferralResult {
  final String referrerName;
  final int discountPercent;

  const ApplyReferralResult({
    required this.referrerName,
    required this.discountPercent,
  });

  factory ApplyReferralResult.fromJson(Map<String, dynamic> json) =>
      ApplyReferralResult(
        referrerName: json['referrerName'] as String? ?? '',
        discountPercent: (json['discountPercent'] as num?)?.toInt() ?? 0,
      );
}
