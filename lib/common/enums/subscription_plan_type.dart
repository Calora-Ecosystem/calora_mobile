enum SubscriptionPlanType {
  free('Free'),
  premium('Premium'),
  family('Family'),
  pro('Pro');

  const SubscriptionPlanType(this.apiName);

  final String apiName;

  bool get isFree => this == free;
  bool get isPremium => this == premium;
  bool get isFamily => this == family;
  bool get isPro => this == pro;

  static SubscriptionPlanType fromApi(String? value) =>
      values.firstWhere((type) => type.apiName == value, orElse: () => free);

  String toApi() => apiName;
}
