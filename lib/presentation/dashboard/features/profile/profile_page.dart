import 'package:auto_route/annotations.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/presentation/dashboard/features/profile/management/profile_management.dart';
import 'package:calora/presentation/dashboard/features/profile/management/profile_manager.dart';
import 'package:calora/widgets/profile_cards/bmi_card/bmi_card.dart';
import 'package:calora/widgets/profile_cards/profile_card.dart';
import 'package:calora/widgets/profile_cards/settings_card.dart' show SettingsCard;
import 'package:flutter/material.dart';
import 'package:management/management.dart';

@RoutePage()
class ProfilePage extends Managed<ProfileManager, ProfileState, ProfileEffect> {
  const ProfilePage({super.key});

  @override
  void init(context, manager) {}

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
                      surname: 'Hasanov',
                      name: 'Nodir',
                      email: 'hasanovnodir2005@gmail.com',
                      onEdit: () {},
                    ),
                    const SizedBox(height: 16),
                    BmiCard(bmi: 37.5, weight: 87, targetWeight: 70),
                    SizedBox(height: 16),
                    SettingsCard(
                      onAccountTap: () {},
                      onNormsTap: () {},
                      onLanguageTap: () {},
                      onNotificationsTap: () {},
                      onInviteTap: () {},
                      onAboutTap: () {},
                      onHelpTap: () {},
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
}
