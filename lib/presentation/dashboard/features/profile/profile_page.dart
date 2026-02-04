import 'package:auto_route/auto_route.dart';
import 'package:calora/common/base/profile_store.dart';
import 'package:calora/common/extensions/bottom_sheet.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/domain/model/profile/profile_request.dart';
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
import 'package:flutter/material.dart';
import 'package:management/management.dart';
import 'package:share_plus/share_plus.dart';

@RoutePage()
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  bool _showBmiProgress(String? goal) {
    final g = (goal ?? '').trim();
    return g != 'SaveCurrent';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ProfileRequest>(
      stream: profileStore.stream(),
      initialData: const ProfileRequest(),
      builder: (context, snapshot) {
        final profile = snapshot.data ?? const ProfileRequest();
        return Scaffold(
          body: Stack(
            children: [
              Positioned.fill(child: Assets.icons.background.image(fit: BoxFit.fill)),
              SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Column(
                      children: [
                        ProfileCard(
                          surname: profile.name ?? '',
                          name: profile.name ?? '',
                          email: profile.email ?? '',
                          onEdit: () => _openProfileDetailPage(
                            context,
                            profile.userId?.toString() ?? '',
                          ),
                        ),
                        const SizedBox(height: 16),
                        BmiCard(
                          showProgress: _showBmiProgress(profile.goal),
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
                          onInviteTap: () {
                            SharePlus.instance.share(
                              ShareParams(
                                text:
                                    "Men Calora ilovasidan foydalanayapman.\nSiz ham sog'lom hayot uchun yuklab oling!",
                              ),
                            );
                          },
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
        );
      },
    );
  }

  void _openAccountDetailPage(BuildContext context) async {
    await context.router.push(AccountDetailRoute());
    // ✅ hech narsa shart emas, agar AccountDetail ichida profileStore.updateProfile(...) bo‘lsa
    // stream avtomatik update qiladi
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
