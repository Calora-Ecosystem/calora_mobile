import 'package:calora/domain/model/premium/family_code.dart';

class CouponUser {
  final int userId;
  final String name;
  final String phone;

  const CouponUser({required this.userId, this.name = '', this.phone = ''});

  factory CouponUser.fromJson(Map<String, dynamic> json) => CouponUser(
    userId: (json['userId'] as num?)?.toInt() ?? 0,
    name: (json['name'] as String?)?.trim() ?? '',
    phone: (json['phone'] as String?)?.trim() ?? '',
  );
}

class FamilyCoupon {
  final int id;
  final String code;
  final int amount;
  final bool isActive;
  final FamilyCodeStatus status;
  final DateTime? expireAt;
  final DateTime? createdAt;
  final DateTime? usedAt;
  final List<CouponUser> usedByUsers;

  const FamilyCoupon({
    required this.id,
    required this.code,
    this.amount = 0,
    this.isActive = true,
    this.status = FamilyCodeStatus.active,
    this.expireAt,
    this.createdAt,
    this.usedAt,
    this.usedByUsers = const [],
  });

  factory FamilyCoupon.fromJson(Map<String, dynamic> json, {DateTime? now}) {
    final isActive = json['isActive'] as bool? ?? true;
    final expireAt = _date(json['expireAt']);
    final usedAt = _date(json['usedAt']);
    final usedByUsers = switch (json['usedByUsers']) {
      final List<dynamic> users when users.isNotEmpty =>
        users
            .whereType<Map<String, dynamic>>()
            .map(CouponUser.fromJson)
            .toList(),
      _ when json['usedByUserId'] is num || json['usedByName'] is String => [
        CouponUser(
          userId: (json['usedByUserId'] as num?)?.toInt() ?? 0,
          name: (json['usedByName'] as String?)?.trim() ?? '',
        ),
      ],
      _ => const <CouponUser>[],
    };
    return FamilyCoupon(
      id: (json['id'] as num?)?.toInt() ?? 0,
      code: json['code'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      isActive: isActive,
      status: switch ((json['status'] as String?)?.trim().toLowerCase()) {
        'active' => FamilyCodeStatus.active,
        'redeemed' || 'used' => FamilyCodeStatus.redeemed,
        'expired' => FamilyCodeStatus.expired,
        _ when usedByUsers.isNotEmpty || usedAt != null =>
          FamilyCodeStatus.redeemed,
        _
            when !isActive ||
                (expireAt != null &&
                    expireAt.isBefore(now ?? DateTime.now())) =>
          FamilyCodeStatus.expired,
        _ => FamilyCodeStatus.active,
      },
      expireAt: expireAt,
      createdAt: _date(json['createdAt']),
      usedAt: usedAt,
      usedByUsers: usedByUsers,
    );
  }

  String? get redeemedBy {
    final user = usedByUsers.firstOrNull;
    if (user == null) return null;
    return user.name.isNotEmpty ? user.name : user.phone;
  }

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toLocal() : null;
}
