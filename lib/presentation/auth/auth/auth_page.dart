import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/bottom_sheet.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/common/widgets/snack_bar/custom_snack_bar.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/auth/auth/management/auth_management.dart';
import 'package:calora/presentation/auth/auth/management/auth_manager.dart';
import 'package:calora/presentation/log/log_files_page.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

@RoutePage()
class AuthPage extends Managed<AuthManager, AuthState, AuthEffect> {
  const AuthPage({super.key});

  @override
  void init(context, manager) {}

  @override
  void listener(context, manager, effect) {
    effect.when(
      verify: (verification) {
        context.router.push(VerifyRoute(verification: verification));
      },
      showError: (message) {
        CustomSnackBar.show(context, message);
      },
    );
  }

  @override
  Widget builder(context, manager, state) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Assets.icons.background.image(fit: BoxFit.fill)),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                  Assets.icons.iconCalora.svg(),
                  const SizedBox(height: 32),
                  TextField(
                    controller: manager.controller,
                    decoration: InputDecoration(hintText: Strings.emailAddress),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: Button(
                      loading: state.loading,
                      onPressed: manager.login,
                      text: Strings.doContinue,
                      textColor: context.colors.textWhite,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(child: Container(height: 1, color: context.colors.accentSub)),
                      const SizedBox(width: 8),
                      Strings.or.text(14, 18, 500).c(context.colors.textStrong),
                      const SizedBox(width: 8),
                      Expanded(child: Container(height: 1, color: context.colors.accentSub)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Button(
                    type: ButtonType.secondary,
                    onPressed: () {},
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Assets.icons.apple.svg(),
                        const SizedBox(width: 8),
                        Strings.continueWithApple.text(14, 18, 500).c(context.colors.textStrong),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Button(
                    type: ButtonType.secondary,
                    onPressed: () {},
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Assets.icons.google.svg(),
                        const SizedBox(width: 8),
                        Strings.continueWithGoogle.text(14, 18, 500).c(context.colors.textStrong),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Checkbox(value: state.checked, onChanged: manager.setChecked),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 14,
                              height: 18 / 14,
                              fontWeight: FontWeight.w500,
                              color: context.colors.neutral600Secondary,
                            ),
                            children: [
                              TextSpan(text: Strings.iReadAndAgree),
                              TextSpan(
                                text: ' ${Strings.termsOfUseLink} ',
                                style: TextStyle(color: context.colors.informationBase),
                                recognizer: manager.termsRecognizer,
                              ),
                              TextSpan(text: Strings.readAndAgreeEnd),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _logFilePages(BuildContext context) {
    context.showAppBottomSheet(child: const LogFilesPage());
  }
}
