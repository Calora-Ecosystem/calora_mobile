import 'package:auto_route/auto_route.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/presentation/dashboard/features/profile/features/about_calora/about_calora_page.dart';
import 'package:calora/presentation/dashboard/features/profile/features/change_localization/change_localization.dart';
import 'package:calora/presentation/dashboard/features/profile/features/help_page/help_page.dart';
import 'package:calora/presentation/dashboard/features/profile/management/main_profile_management.dart';
import 'package:calora/presentation/dashboard/features/profile/management/main_profile_manager.dart';
import 'package:calora/widgets/profile_cards/bmi_card/bmi_card.dart';
import 'package:calora/widgets/profile_cards/profile_card.dart';
import 'package:calora/widgets/profile_cards/settings_card.dart' show SettingsCard;
import 'package:flutter/material.dart';
import 'package:management/management.dart';
import 'package:share_plus/share_plus.dart';

@RoutePage()
class MainProfilePage extends Managed<MainProfileManager, MainProfileState, MainProfileEffect> {
  const MainProfilePage({super.key});

  @override
  void init(context, manager) {
    manager.getProfile();
  }

  @override
  Widget builder(context, manager, state) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Assets.icons.background.image(fit: BoxFit.fill)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ProfileCard(
                      surname: state.profile.name,
                      name: state.profile.name,
                      email: state.profile.email,
                      onEdit: () {
                        context.pushRoute(ProfileRoute(userId: state.profile.userId));
                      },
                    ),
                    const SizedBox(height: 16),
                    BmiCard(
                      bmi: state.profile.bmi,
                      weight: state.profile.weight,
                      targetWeight: state.profile.targetWeight,
                    ),
                    SizedBox(height: 16),
                    SettingsCard(
                      onAccountTap: () {},
                      onNormsTap: () {
                        context.pushRoute(NormsRoute());
                      },
                      onLanguageTap: () {
                        showLanguageBottomSheet(context);
                      },
                      onNotificationsTap: () {},
                      onInviteTap: () {
                        SharePlus.instance.share(
                          ShareParams(
                            text:
                                'Men Calora ilovasidan foydalanayapman 😊.\nSiz ham sog‘lom hayot uchun yuklab oling!',
                          ),
                        );
                      },
                      onAboutTap: () {
                        showAboutBottomSheet(context);
                      },
                      onHelpTap: () {
                        showHelpBottomSheet(context);
                      },
                    ),
                    SizedBox(height: 16),
                    Image.asset('assets/images/yandex-banner.png'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openAccountInfoPage(String profileId, BuildContext context) {
    context.router.push(AccountDetailRoute(profileId: profileId));
  }
}
