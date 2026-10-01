/// Status of a family-plan code (`GET billing/family/codes`).
enum FamilyCodeStatus { active, redeemed, expired }

/// A code the family-plan buyer sends to the second person; redeeming it
/// gives that person [months] of Premium.
class FamilyCode {
  final String code;
  final int months;
  final FamilyCodeStatus status;
  final DateTime? createdAt;

  /// The code has to be redeemed by this date.
  final DateTime? expireAt;
  final DateTime? redeemedAt;

  /// Name of the person who redeemed it.
  final String? redeemedBy;

  const FamilyCode({
    required this.code,
    this.months = 1,
    this.status = FamilyCodeStatus.active,
    this.createdAt,
    this.expireAt,
    this.redeemedAt,
    this.redeemedBy,
  });

  factory FamilyCode.fromJson(Map<String, dynamic> json) => FamilyCode(
    code: json['code'] as String? ?? '',
    months: (json['months'] as num?)?.toInt() ?? 1,
    status: switch ((json['status'] as String?)?.toLowerCase()) {
      'redeemed' => FamilyCodeStatus.redeemed,
      'expired' => FamilyCodeStatus.expired,
      _ => FamilyCodeStatus.active,
    },
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    expireAt: DateTime.tryParse(json['expireAt'] as String? ?? ''),
    redeemedAt: DateTime.tryParse(json['redeemedAt'] as String? ?? ''),
    redeemedBy: json['redeemedBy'] as String?,
  );
}

/// Result of redeeming a family code (`POST billing/family/redeem`).
class FamilyRedeemResult {
  /// Who bought the family plan and sent the code.
  final String? ownerName;
  final int months;
  final DateTime? endsAt;

  /// Premium lives in the JWT — refresh the token right away.
  final bool requiresTokenRefresh;

  const FamilyRedeemResult({
    this.ownerName,
    this.months = 1,
    this.endsAt,
    this.requiresTokenRefresh = true,
  });

  factory FamilyRedeemResult.fromJson(Map<String, dynamic> json) =>
      FamilyRedeemResult(
        ownerName: json['ownerName'] as String?,
        months: (json['months'] as num?)?.toInt() ?? 1,
        endsAt: DateTime.tryParse(json['endsAt'] as String? ?? ''),
        requiresTokenRefresh: json['requiresTokenRefresh'] as bool? ?? true,
      );
}
