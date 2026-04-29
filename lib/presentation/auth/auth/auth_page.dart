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
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

@RoutePage()
class AuthPage extends Managed<AuthManager, AuthState, AuthEffect> {
  final bool? isUzbekistan;

  AuthPage({super.key, this.isUzbekistan});

  @override
  void init(context, manager) {
    manager.setIsUzbekistan(value: isUzbekistan);
  }

  @override
  void listener(context, manager, effect) {
    effect.when(
      verify: (verification) => context.router.push(VerifyRoute(verification: verification)),
      showError: (message) => CustomSnackBar.show(context, message),
      openDashboard: () => context.router.replaceAll([DashboardRoute()]),
      openQuestions: (email) => context.router.push(
        QuestionsRoute(),
      ),
    );
  }

  final MaskTextInputFormatter phoneFormatter = MaskTextInputFormatter(
    mask: '## ### ## ##',
    filter: {'#': RegExp(r'[0-9]')},
  );

  @override
  Widget builder(context, manager, state) {
    return Stack(
      children: [
        Positioned.fill(child: Assets.icons.background.image(fit: BoxFit.fill)),
        Scaffold(
          backgroundColor: context.colors.transparent,
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Assets.icons.iconCalora.svg(),
                      const SizedBox(height: 32),
                      if (!state.isUzbekistan) ...[
                        TextField(
                          controller: manager.controller,
                          cursorColor: context.colors.accentSub,
                          decoration: InputDecoration(
                            hintText: Strings.emailAddress,
                          ),
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
                            Expanded(
                              child: Container(
                                height: 1,
                                color: context.colors.accentSub,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Strings.or.text(14, 18, 500).c(context.colors.textStrong),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: context.colors.accentSub,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Button(
                          type: ButtonType.secondary,
                          onPressed: () => manager.loginWithApple(),
                          loading: state.loading,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Assets.icons.apple.svg(),
                              const SizedBox(width: 8),
                              Strings.continueWithApple
                                  .text(14, 18, 500)
                                  .c(context.colors.textStrong),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Button(
                          type: ButtonType.secondary,
                          onPressed: () => manager.loginWithGoogle(),
                          loading: state.loading,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Assets.icons.google.svg(),
                              const SizedBox(width: 8),
                              Strings.continueWithGoogle
                                  .text(14, 18, 500)
                                  .c(context.colors.textStrong),
                            ],
                          ),
                        ),
                      ] else ...[
                        TextFormField(
                          controller: manager.controller,
                          cursorColor: context.colors.accentSub,
                          inputFormatters: [phoneFormatter],
                          keyboardType: TextInputType.phone,
                          style: TextStyle(
                            color: context.colors.neutral900Primary,
                            fontSize: 14,
                            height: 18 / 14,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: '00 000 00 00',
                            prefixIcon: Align(
                              heightFactor: 1,
                              widthFactor: 1,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: '+998'
                                    .text(14, 18, 500)
                                    .c(
                                      manager.controller.text.trim().isEmpty
                                          ? context.colors.textSub
                                          : context.colors.neutral900Primary,
                                    ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Button(
                          loading: state.loading,
                          onPressed: manager.login,
                          text: Strings.doContinue,
                          textColor: context.colors.textWhite,
                        ),
                      ],
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Checkbox(
                            value: state.checked,
                            onChanged: manager.setChecked,
                            activeColor: context.colors.accentSub,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
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
                                    style: TextStyle(
                                      color: context.colors.informationBase,
                                    ),
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
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _logFilePages(BuildContext context) {
    context.showAppBottomSheet(child: const LogFilesPage());
  }
}
