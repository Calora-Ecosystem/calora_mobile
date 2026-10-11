import 'package:calora/common/enums/subscription_plan_type.dart';
import 'package:collection/collection.dart';

class PlanFeature {
  const PlanFeature({required this.key, required this.value});

  factory PlanFeature.fromJson(Map<String, dynamic> json) => PlanFeature(
    key: json['featureKey'] as String? ?? '',
    value: '${json['value'] ?? ''}',
  );

  final String key;
  final String value;
}

class PremiumPlanModel {
  const PremiumPlanModel({
    required this.id,
    this.type = SubscriptionPlanType.premium,
    this.duration = 1,
    this.isActive = true,
    this.fee = 0,
    this.originalFee = 0,
    this.isPopular = false,
    this.referralDiscountPercent = 0,
    this.discountedFee = 0,
    this.features = const [],
  });

  factory PremiumPlanModel.fromJson(Map<String, dynamic> json) {
    int asInt(Object? value) => (value as num?)?.toInt() ?? 0;
    final features = json['features'];
    return PremiumPlanModel(
      id: asInt(json['id']),
      type: SubscriptionPlanType.fromApi(json['plan'] as String?),
      duration: asInt(json['duration']),
      isActive: json['isActive'] as bool? ?? true,
      fee: asInt(json['fee']),
      originalFee: asInt(json['originalFee']),
      isPopular: json['isPopular'] as bool? ?? false,
      referralDiscountPercent: asInt(json['referralDiscountPercent']),
      discountedFee: asInt(json['discountedFee']),
      features: features is List
          ? features
                .whereType<Map<String, dynamic>>()
                .map(PlanFeature.fromJson)
                .toList()
          : const [],
    );
  }

  static List<PremiumPlanModel> listFromJson(List<dynamic> json) => json
      .whereType<Map<String, dynamic>>()
      .map(PremiumPlanModel.fromJson)
      .toList();

  final int id;
  final SubscriptionPlanType type;
  final int duration;
  final bool isActive;
  final int fee;
  final int originalFee;
  final bool isPopular;
  final int referralDiscountPercent;
  final int discountedFee;
  final List<PlanFeature> features;

  bool get isFamily => type.isFamily;

  bool get hasReferralDiscount => referralDiscountPercent > 0;

  int get price =>
      hasReferralDiscount && discountedFee > 0 ? discountedFee : fee;
}

class PlanGroup {
  const PlanGroup(this.type, this.packages);

  static const sellable = [
    SubscriptionPlanType.premium,
    SubscriptionPlanType.family,
  ];

  final SubscriptionPlanType type;
  final List<PremiumPlanModel> packages;

  bool get isFamily => type.isFamily;

  PremiumPlanModel? byDuration(int months) =>
      packages.firstWhereOrNull((package) => package.duration == months);

  static List<PlanGroup> of(List<PremiumPlanModel> plans) => [
    for (final type in sellable)
      if (_packagesOf(plans, type) case final packages when packages.isNotEmpty)
        PlanGroup(type, packages),
  ];

  static List<PremiumPlanModel> _packagesOf(
    List<PremiumPlanModel> plans,
    SubscriptionPlanType type,
  ) {
    final byDuration = <int, PremiumPlanModel>{};
    for (final plan in plans) {
      if (plan.type == type && plan.isActive && plan.duration > 0) {
        byDuration.putIfAbsent(plan.duration, () => plan);
      }
    }
    return byDuration.values.sorted((a, b) => b.duration.compareTo(a.duration));
  }
}
