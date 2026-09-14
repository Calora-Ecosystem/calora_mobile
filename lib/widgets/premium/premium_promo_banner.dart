import 'package:auto_route/auto_route.dart';
import 'package:calora/common/base/manager_builder.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/presentation/app/app/management/app_management.dart';
import 'package:calora/presentation/app/app/management/app_manager.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

/// Compact page-header premium upsell used across Home / Calories / Course /
/// Steps. It mirrors the profile [PremiumEntryCard] look — the brand
/// `premium_entry_background` surface with the 3D `premium_fire` trophy — but
/// drops the crown/price line in favour of a single "unlock premium" button.
///
/// Auto-hides for users who already have premium.
class PremiumPromoBanner extends StatelessWidget {
  final VoidCallback? onTap;

  const PremiumPromoBanner({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ManagerBuilder<AppState, AppEffect>(
      manager: context.read<AppManager>(),
      properties: (state) => [state.isUserPremium],
      builder: (context, state) {
        if (state.isUserPremium) return const SizedBox.shrink();
        final colors = context.colors;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap:
              onTap ?? () => context.router.push(const PremiumFeaturesRoute()),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: AssetImage(Assets.images.premiumEntryBackground.path),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.accentSub.withValues(alpha: 0.22),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(18).copyWith(right: 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Strings.caloraPremium
                            .text(22, 28, 800)
                            .c(colors.white)
                            .copyWith(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        const SizedBox(height: 12),
                        _openButton(context),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Assets.images.premiumFire.image(width: 92, height: 92),
              ],
            ),
          ),
        );
      },
    );
  }

  /// White pill CTA — the accent label reads clearly on the brand surface.
  Widget _openButton(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 9, 12, 9),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: colors.black.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Strings.pwCtaButton.text(13, 16, 700).c(colors.accentSub),
          const SizedBox(width: 5),
          Icon(Icons.arrow_forward_rounded, size: 16, color: colors.accentSub),
        ],
      ),
    );
  }
}
