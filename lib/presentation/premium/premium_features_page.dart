import 'package:auto_route/annotations.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/premium/premium_sheet.dart';
import 'package:calora/widgets/app_bar/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

@RoutePage()
class PremiumFeaturesPage extends StatelessWidget {
  const PremiumFeaturesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final features = _premiumFeatures;

    return Scaffold(
      backgroundColor: context.colors.white,
      appBar: CustomAppBar(
        title: Strings.caloraPremium.text(17, 22, 600).c(context.colors.textStrong),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                physics: const ClampingScrollPhysics(),
                itemCount: features.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final feature = features[index];
                  return _PremiumFeatureCard(
                    title: feature.title,
                    description: feature.description,
                    icon: feature.icon,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ).copyWith(top: 0),
              child: Button(
                text: Strings.payment,
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    useSafeArea: true,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (_) => const PremiumSheet(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumFeature {
  final String title;
  final String description;
  final SvgGenImage icon;

  const _PremiumFeature({required this.title, required this.description, required this.icon});
}

final List<_PremiumFeature> _premiumFeatures = [
  _PremiumFeature(
    title: Strings.aiHealthAnalysisTitle,
    description: Strings.aiHealthAnalysisSubtitle,
    icon: Assets.icons.brain,
  ),
  _PremiumFeature(
    title: Strings.aiFoodPhotoAnalysisTitle,
    description: Strings.aiFoodPhotoAnalysisSubtitle,
    icon: Assets.icons.camera,
  ),
  _PremiumFeature(
    title: Strings.voiceFoodInputTitle,
    description: Strings.voiceFoodInputSubtitle,
    icon: Assets.icons.icMicro,
  ),
  _PremiumFeature(
    title: Strings.men30DayWorkoutTitle,
    description: Strings.men30DayWorkoutSubtitle,
    icon: Assets.icons.malePerson,
  ),
  _PremiumFeature(
    title: Strings.women30DayWorkoutTitle,
    description: Strings.women30DayWorkoutSubtitle,
    icon: Assets.icons.femalePerson,
  ),
  _PremiumFeature(
    title: Strings.adFreeExperienceTitle,
    description: Strings.adFreeExperienceSubtitle,
    icon: Assets.icons.shield,
  ),
];

class _PremiumFeatureCard extends StatelessWidget {
  final String title;
  final String description;
  final SvgGenImage icon;

  const _PremiumFeatureCard({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: context.colors.backgroundElevation,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          icon.svg(
            height: 24,
            width: 24,
            colorFilter: ColorFilter.mode(
              context.colors.accentSub,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title
                    .text(16, 20, 500)
                    .c(context.colors.textStrong)
                    .copyWith(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                const SizedBox(height: 8),
                description
                    .text(14, 16, 400)
                    .c(context.colors.textSub)
                    .copyWith(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
