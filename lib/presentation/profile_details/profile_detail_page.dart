import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/common/automatic_tracking/automatick_tracking.dart';
import 'package:calora/presentation/common/confirm/confirm_page.dart';
import 'package:calora/presentation/profile_details/management/profile_detail_management.dart';
import 'package:calora/presentation/profile_details/management/profile_detail_manager.dart';
import 'package:calora/widgets/app_bar/custom_app_bar.dart';
import 'package:calora/widgets/premium/premium_entry_card.dart';
import 'package:calora/widgets/social_button/social_button.dart';
import 'package:calora/widgets/svg_buttons_row/svg_buttons_row.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

@RoutePage()
class ProfileDetailPage
    extends Managed<ProfileDetailManager, ProfileDetailState, ProfileDetailEffect> {
  final String userId;

  const ProfileDetailPage({required this.userId, super.key});

  @override
  void listener(context, manager, effect) {
    effect.when(
      showDialog: () => showDialog(
        context: context,
        builder: (_) => ConfirmPage(
          onConfirm: () => logOut(manager, context),
          onCancel: () => Navigator.pop(context),
          title: Strings.areYouSureWantLogOut,
          confirmText: Strings.logOut,
          cancelText: Strings.rejection,
        ),
      ),
      showDeleteAccountDialog: () => showDialog(
        context: context,
        builder: (_) => ConfirmPage(
          onConfirm: () {
            Navigator.pop(context);
            manager.deleteAccount(userId);
          },
          onCancel: () => Navigator.pop(context),
          title: Strings.areYouSureDeleteAccount,
          confirmText: Strings.deleteAccount,
          cancelText: Strings.rejection,
        ),
      ),
      accountDeleted: () => context.router.replaceAll([AuthRoute()]),
      deleteAccountFailed: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Strings.deleteAccountFailed)),
      ),
    );
  }

  @override
  Widget builder(context, manager, state) {
    return Scaffold(
      backgroundColor: context.colors.white,
      appBar: CustomAppBar(title: Strings.profile),
      body: Column(
        children: [
          Divider(color: context.colors.strokeSoft),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRow(Strings.profileUserId, userId, context),
                _buildRow(
                  Strings.profileSubscription,
                  Strings.restorePurchase,
                  context,
                ),
                const SizedBox(height: 16),
                SocialButton(
                  label: Strings.throughAppleId,
                  icon: Assets.icons.apple.svg(),
                  onTap: () {},
                ),
                const SizedBox(height: 16),
                SocialButton(
                  label: Strings.byMail,
                  icon: Assets.icons.mail.svg(),
                  isSelected: true,
                  onTap: () {},
                ),
                const SizedBox(height: 16),
                SocialButton(
                  label: Strings.viaGoogle,
                  icon: Assets.icons.google.svg(),
                  isSelected: true,
                  onTap: () {},
                ),
                const SizedBox(height: 16),
                PremiumEntryCard(),
                const SizedBox(height: 8),
                Strings.automaticTracking.text(16, 20, 500).c(context.colors.textStrong),
                const SizedBox(height: 8),
                SvgButtonsRow(
                  isAppleHealthSelected: state.isAppleHealthSelected,
                  isSamsungHealthSelected: state.isSamsungHealthSelected,
                  isGarminSelected: state.isGarminSelected,
                  isGoogleFitSelected: state.isAppleHealthSelected,
                  onGoogleFitTap: () {
                    showAutomaticTrackingSheet(
                      context,
                      onConnectTap: () {
                        manager.onGoogleFitTap();
                      },
                      secondAsset: Assets.images.googleFit.image(),
                      title: 'Google Fit',
                    );
                  },
                  onAppleHealthTap: () {
                    showAutomaticTrackingSheet(
                      context,
                      onConnectTap: () {
                        manager.onAppleHealthTap();
                      },
                      secondAsset: Assets.images.iosHealth.image(),
                      title: 'Apple Health',
                    );
                  },
                  onGarminTap: () {
                    showAutomaticTrackingSheet(
                      context,
                      onConnectTap: () {
                        manager.onGarminTap();
                      },
                      secondAsset: Assets.images.garmin.image(),
                      title: 'Garmin',
                    );
                  },
                  onSamsungHealthTap: () {
                    showAutomaticTrackingSheet(
                      context,
                      onConnectTap: () {
                        manager.onSamsungHealthTap();
                      },
                      secondAsset: Assets.images.health.image(),
                      title: 'Samsung Health',
                    );
                  },
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => manager.logOutDialog(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: context.colors.backgroundElevation,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Assets.icons.logout.svg(),
                        const SizedBox(width: 8),
                        Strings.logOut.text(14, 16, 600).c(context.colors.errorBase),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: state.isDeletingAccount ? null : () => manager.deleteAccountDialog(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: context.colors.errorLighter,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (state.isDeletingAccount)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Strings.deleteAccount.text(14, 16, 600).c(context.colors.errorBase),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void logOut(ProfileDetailManager manager, BuildContext context) {
    manager.logOut();
    context.router.replaceAll([AuthRoute()]);
  }

  Widget _buildRow(String label, String value, BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              label.text(14, 16, 400).c(context.colors.textStrong),
              value.text(14, 16, 400).c(context.colors.textStrong),
            ],
          ),
        ),
        Divider(color: context.colors.strokeSoft),
      ],
    );
  }
}
