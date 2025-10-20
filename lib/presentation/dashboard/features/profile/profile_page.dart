import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/bottom_sheet.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/common/widgets/shimmer/shimmer.dart';
import 'package:calora/common/widgets/shimmer/shimmer_child.dart';
import 'package:calora/domain/model/profile/profile.dart';
import 'package:calora/presentation/about/about_page.dart' show AboutPage;
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/dashboard/features/profile/management/profile_manager.dart';
import 'package:calora/presentation/help/help_page.dart';
import 'package:calora/presentation/language/bottom_sheet/language_bottom_sheet.dart';
import 'package:calora/widgets/profile_cards/bmi_card/bmi_card.dart';
import 'package:calora/widgets/profile_cards/profile_card.dart';
import 'package:calora/widgets/profile_cards/settings_card.dart' show SettingsCard;
import 'package:flutter/material.dart';
import 'package:management/management.dart';
import 'package:share_plus/share_plus.dart';

import 'management/profile_management.dart';

@RoutePage()
class ProfilePage extends Managed<ProfileManager, ProfileState, ProfileEffect> {
  const ProfilePage({super.key});

  @override
  void init(context, manager) {
    manager.getProfile();
  }

  @override
  Widget builder(context, manager, state) {
    return Scaffold(
      body: Shimmer(
        child: Stack(
          children: [
            Positioned.fill(child: Assets.icons.background.image(fit: BoxFit.fill)),
            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    children: [
                      ShimmerLoading(
                        loading: state.isLoading,
                        shimmerChild: ShimmerChild(
                          color: context.colors.white,
                          radius: 20,
                          width: double.infinity,
                          height: 80,
                        ),
                        child: ProfileCard(
                          surname: state.profile?.name ?? '',
                          name: state.profile?.name ?? '',
                          email: state.profile?.email ?? '',
                          onEdit: () {
                            _openProfileDetailPage(context, state.profile?.userId ?? '');
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      ShimmerLoading(
                        loading: state.isLoading,
                        shimmerChild: ShimmerChild(
                          color: context.colors.white,
                          radius: 20,
                          width: double.infinity,
                          height: 250,
                        ),
                        child: BmiCard(
                          bmi: state.profile?.bmi ?? 0,
                          weight: state.profile?.weight ?? 0,
                          targetWeight: state.profile?.targetWeight ?? 0,
                        ),
                      ),
                      SizedBox(height: 16),
                      SettingsCard(
                        onAccountTap: () => _openAccountDetailPage(context, manager),
                        onNormsTap: () => _openNormsPage(context),
                        onLanguageTap: () => _showLanguageBottomSheet(context),
                        onNotificationsTap: () {
                          _openNotificationSettingsPage(context);
                        },
                        onInviteTap: () {
                          SharePlus.instance.share(
                            ShareParams(
                              text:
                                  'Men Calora ilovasidan foydalanayapman 😊.\nSiz ham sog‘lom hayot uchun yuklab oling!',
                            ),
                          );
                        },
                        onAboutTap: () {
                          _showAboutBottomSheet(context);
                        },
                        onHelpTap: () {
                          _showHelpBottomSheet(context);
                        },
                      ),
                      SizedBox(height: 16),
                      Assets.images.yandexBanner.image(),
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

  void _openAccountDetailPage(BuildContext context, ProfileManager manager) {
    context.router.push(AccountDetailRoute(profile: Profile()));
    manager.getProfile();
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
    context.showAppBottomSheet(
      minChildSize: 0.2,
      initialChildSize: 0.3,
      maxChildSize: 0.3,
      child: const HelpPage(),
    );
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
