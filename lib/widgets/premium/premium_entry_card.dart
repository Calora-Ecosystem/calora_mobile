import 'package:auto_route/auto_route.dart';
import 'package:calora/common/di/injection.dart';
import 'package:calora/common/extensions/number_extension/number_extension.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/domain/model/premium/premium_plan_model.dart';
import 'package:calora/domain/repo/common/common_repo.dart';
import 'package:calora/domain/repo/premium/premium_repo.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/premium/premium_builder.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class PremiumEntryCard extends StatelessWidget {
  final VoidCallback? onTap;
  const PremiumEntryCard({super.key, this.onTap});

  static Future<PremiumPlanModel?>? _cheapestPackage;

  static Future<PremiumPlanModel?> _loadCheapestPackage() async {
    try {
      final isUzbekistan = await getIt<CommonRepo>()
          .getIsUzbekistan()
          .cacheOrNetwork;
      if (!isUzbekistan) return null;
      final plans = await getIt<PremiumRepo>().getPremiumPlans();
      return cheapestPerMonth(
        PlanGroup.of(
          plans,
        ).firstWhereOrNull((group) => group.type.isPremium)?.packages,
      );
    } catch (_) {
      return null;
    }
  }

  @visibleForTesting
  static PremiumPlanModel? cheapestPerMonth(List<PremiumPlanModel>? packages) =>
      packages
          ?.where((package) => package.duration > 0)
          .fold<PremiumPlanModel?>(
            null,
            (cheapest, package) =>
                cheapest == null ||
                    package.price / package.duration <
                        cheapest.price / cheapest.duration
                ? package
                : cheapest,
          );

  static String _priceLine(PremiumPlanModel? package) {
    if (package == null) return Strings.pwCtaButton;
    final monthly = (package.price / package.duration).round().formatPrice();
    return package.duration == 1
        ? Strings.pricePerMonth(price: monthly)
        : 'tf_yearly_sub'.tr(namedArgs: {'price': monthly});
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBuilder(
      builder: (context, isPremium) {
        if (isPremium) return const SizedBox.shrink();
        return GestureDetector(
          onTap:
              onTap ?? () => context.router.push(const PremiumFeaturesRoute()),
          child: Container(
            height: 98,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: AssetImage(Assets.images.premiumEntryBackground.path),
                fit: BoxFit.cover,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20).copyWith(right: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Strings.caloraPremium
                            .text(24, 30, 700)
                            .c(context.colors.white)
                            .copyWith(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        FutureBuilder<PremiumPlanModel?>(
                          future: _cheapestPackage ??= _loadCheapestPackage(),
                          builder: (context, snapshot) =>
                              (snapshot.connectionState == ConnectionState.done
                                      ? _priceLine(snapshot.data)
                                      : '')
                                  .text(16, 20, 500)
                                  .c(context.colors.white)
                                  .copyWith(
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
                Assets.images.premiumFire.image(),
                const SizedBox(width: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}
