/// Free AI recognition allowance (`GET food/recognization/quota`). Photo scan
/// and voice add draw from the same pool; Premium is [unlimited].
class AiQuota {
  final bool unlimited;
  final int limit;
  final int used;
  final int remaining;

  const AiQuota({
    this.unlimited = false,
    this.limit = 5,
    this.used = 0,
    this.remaining = 5,
  });

  bool get canUse => unlimited || remaining > 0;

  factory AiQuota.fromJson(Map<String, dynamic> json) => AiQuota(
    unlimited: json['unlimited'] as bool? ?? false,
    limit: (json['limit'] as num?)?.toInt() ?? 5,
    used: (json['used'] as num?)?.toInt() ?? 0,
    remaining: (json['remaining'] as num?)?.toInt() ?? 0,
  );
}
