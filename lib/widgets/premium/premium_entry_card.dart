import 'package:auto_route/auto_route.dart';
import 'package:calora/common/base/manager_builder.dart';
import 'package:calora/common/extensions/number_extension/number_extension.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/presentation/app/app/management/app_management.dart';
import 'package:calora/presentation/app/app/management/app_manager.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

class PremiumEntryCard extends StatelessWidget {
  final VoidCallback? onTap;
  const PremiumEntryCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ManagerBuilder<AppState, AppEffect>(
      manager: context.read<AppManager>(),
      properties: (state) => [state.isUserPremium],
      builder: (context, state) {
        if (state.isUserPremium) return const SizedBox.shrink();
        return GestureDetector(
          onTap: onTap ?? () => context.router.push(const PremiumFeaturesRoute()),
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
                            .copyWith(maxLines: 1, overflow: TextOverflow.ellipsis),
                        Strings.pricePerMonth(
                              price: 49000.formatPrice(),
                            )
                            .text(16, 20, 500)
                            .c(context.colors.white)
                            .copyWith(maxLines: 1, overflow: TextOverflow.ellipsis),
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
