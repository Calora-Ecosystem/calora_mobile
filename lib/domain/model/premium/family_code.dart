enum FamilyCodeStatus { active, redeemed, expired }

bool isFamilyCode(String code) =>
    code.trim().toUpperCase().startsWith('FAMILY');

class FamilyRedeemResult {
  const FamilyRedeemResult({
    this.ownerName,
    this.months = 1,
    this.requiresTokenRefresh = true,
  });

  final String? ownerName;
  final int months;
  final bool requiresTokenRefresh;
}

class FamilyCodeException implements Exception {
  const FamilyCodeException(this.code);

  static const notFound = 'family_code_not_found';
  static const used = 'family_code_used';
  static const expired = 'family_code_expired';
  static const notCovered = 'family_code_not_covered';
  static const self = 'family_code_self';

  final String code;

  @override
  String toString() => code;
}
