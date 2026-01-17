enum SubscriptionPlanType {
  free,
  premium,
  pro
  ;

  bool get isFree => this == SubscriptionPlanType.free;
  bool get isPremium => this == SubscriptionPlanType.premium;
  bool get isPro => this == SubscriptionPlanType.pro;

  static SubscriptionPlanType fromApi(String? value) {
    switch (value) {
      case 'Free':
        return SubscriptionPlanType.free;
      case 'Premium':
        return SubscriptionPlanType.premium;
      case 'Pro':
        return SubscriptionPlanType.pro;
      default:
        return SubscriptionPlanType.free;
    }
  }

  String toApi() {
    switch (this) {
      case SubscriptionPlanType.free:
        return 'Free';
      case SubscriptionPlanType.premium:
        return 'Premium';
      case SubscriptionPlanType.pro:
        return 'Pro';
    }
  }
}
