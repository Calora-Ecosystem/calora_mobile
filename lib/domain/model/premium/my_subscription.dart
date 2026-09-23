/// The user's current plan (`GET billing/subscription/my`) for the
/// Profile → Subscription panel.
/// Free, active, or cancelled in the store (Premium kept until [MySubscription.endsAt]).
enum SubscriptionStatus { free, active, cancelled }

class MySubscription {
  final bool isPremium;
  final SubscriptionStatus status;

  /// Paid through App Store / Google Play — plan changes and cancellation
  /// happen in the store.
  final bool managedByStore;

  /// Payment, Admin, Coins or Referral — where the Premium came from.
  final String? source;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int daysLeft;

  /// Click, Payme or Iap for the last confirmed payment.
  final String? provider;
  final int? durationInMonths;
  final bool autoRenew;
  final DateTime? nextPaymentAt;

  const MySubscription({
    this.isPremium = false,
    this.status = SubscriptionStatus.free,
    this.managedByStore = false,
    this.source,
    this.startsAt,
    this.endsAt,
    this.daysLeft = 0,
    this.provider,
    this.durationInMonths,
    this.autoRenew = false,
    this.nextPaymentAt,
  });

  factory MySubscription.fromJson(Map<String, dynamic> json) => MySubscription(
    isPremium: json['isPremium'] as bool? ?? false,
    status: switch ((json['status'] as String?)?.toLowerCase()) {
      'active' => SubscriptionStatus.active,
      'cancelled' => SubscriptionStatus.cancelled,
      _ => SubscriptionStatus.free,
    },
    managedByStore: json['managedByStore'] as bool? ?? false,
    source: json['source'] as String?,
    startsAt: DateTime.tryParse(json['startsAt'] as String? ?? ''),
    endsAt: DateTime.tryParse(json['endsAt'] as String? ?? ''),
    daysLeft: (json['daysLeft'] as num?)?.toInt() ?? 0,
    provider: json['provider'] as String?,
    durationInMonths: (json['durationInMonths'] as num?)?.toInt(),
    autoRenew: json['autoRenew'] as bool? ?? false,
    nextPaymentAt: DateTime.tryParse(json['nextPaymentAt'] as String? ?? ''),
  );
}
