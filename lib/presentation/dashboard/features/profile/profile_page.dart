import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/bottom_sheet.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/common/widgets/feature_tour/feature_tour.dart';
import 'package:calora/domain/model/profile/profile_request.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:calora/presentation/about/about_page.dart' show AboutPage;
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/dashboard/features/profile/management/profile_management.dart';
import 'package:calora/presentation/dashboard/features/profile/management/profile_manager.dart';
import 'package:calora/presentation/help/help_page.dart';
import 'package:calora/presentation/language/bottom_sheet/language_bottom_sheet.dart';
import 'package:calora/widgets/premium/premium_entry_card.dart';
import 'package:calora/widgets/profile_cards/bmi_card/bmi_card.dart';
import 'package:calora/widgets/profile_cards/profile_card.dart';
import 'package:calora/widgets/profile_cards/settings_card.dart' show SettingsCard;
import 'package:calora/widgets/health/health_sync_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';
import 'package:url_launcher/url_launcher.dart';

@RoutePage()
class ProfilePage extends Managed<ProfileManager, ProfileState, ProfileEffect> {
  const ProfilePage({super.key});

  @override
  void init(BuildContext context, ProfileManager manager) {
    manager.initialize();
    super.init(context, manager);
  }

  @override
  Widget builder(BuildContext context, ProfileManager manager, ProfileState state) {
    final profile = state.profile ?? const ProfileRequest();
    return FeatureTourHost(
      tourId: 'tour_profile',
      steps: _profileTourSteps(context),
      child: Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Assets.icons.background.image(fit: BoxFit.fill)),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  children: [
                    KeyedSubtree(
                      key: TourAnchors.profileMain,
                      child: ProfileCard(
                        surname: profile.name ?? '',
                        name: profile.name ?? '',
                        email: profile.email ?? '',
                        onEdit: () => _openProfileDetailPage(
                          context,
                          profile.userId?.toString() ?? '',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    BmiCard(
                      showProgress: state.showBmiProgress,
                      height: profile.height ?? 1,
                      entryWeight: profile.entryWeight ?? 100,
                      weight: profile.weight ?? 0,
                      targetWeight: profile.targetWeight ?? 0,
                    ),
                    const SizedBox(height: 16),
                    SettingsCard(
                      onAccountTap: () => _openAccountDetailPage(context),
                      onNormsTap: () => _openNormsPage(context),
                      onLanguageTap: () => _showLanguageBottomSheet(context),
                      onNotificationsTap: () => _openNotificationSettingsPage(context),
                      onHealthTap: () => HealthSyncBottomSheet.show(context),
                      onInviteTap: () => launchUrl(
                        Uri.parse('https://calora.uz'),
                        mode: LaunchMode.externalApplication,
                      ),
                      onAboutTap: () => _showAboutBottomSheet(context),
                      onHelpTap: () => _showHelpBottomSheet(context),
                    ),
                    const SizedBox(height: 16),
                    PremiumEntryCard(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  /// First-visit coach-mark for the Profile tab.
  List<FeatureTourStep> _profileTourSteps(BuildContext context) {
    Widget mi(IconData i) => Icon(i, size: 16, color: context.colors.accentSub);
    return [
      FeatureTourStep(
        targetKey: TourAnchors.profileMain,
        icon: Icons.person_rounded,
        title: 'ft_profile_title'.tr(),
        description: 'ft_profile_desc'.tr(),
        bullets: [
          FeatureTourBullet(mi(Icons.flag_rounded), 'ft_profile_b1'.tr()),
          FeatureTourBullet(mi(Icons.tune_rounded), 'ft_profile_b2'.tr()),
        ],
      ),
    ];
  }

  void _openAccountDetailPage(BuildContext context) async {
    await context.router.push(AccountDetailRoute());
  }

  void _openProfileDetailPage(BuildContext context, String userId) {
    context.router.push(ProfileDetailRoute(userId: userId));
  }

  void _openNotificationSettingsPage(BuildContext context) {
    context.router.push(NotificationSettingsRoute());
  }

  void _openNormsPage(BuildContext context) {
    context.router.push(NormsRoute());
  }

  void _showHelpBottomSheet(BuildContext context) {
    context.showAppBottomSheet(child: const HelpPage());
  }

  void _showLanguageBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const LanguagePage(),
    );
  }

  void _showAboutBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const AboutPage(),
    );
  }
}
