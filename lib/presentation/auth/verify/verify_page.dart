import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/common/widgets/snack_bar/custom_snack_bar.dart';
import 'package:calora/domain/model/verification/verification.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/auth/verify/management/verify_management.dart';
import 'package:calora/presentation/auth/verify/management/verify_manager.dart';
import 'package:calora/widgets/verify/verify_code_widget.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

@RoutePage()
class VerifyPage extends Managed<VerifyManager, VerifyState, VerifyEffect> {
  const VerifyPage({super.key, required this.verification, this.onVerified});

  final Verification verification;
  final Future<void> Function()? onVerified;

  @override
  void init(context, manager) {
    manager.setInitialVerification(verification);
  }

  @override
  void listener(context, manager, effect) {
    effect.when(
      openQuestions: (email) {
        context.router.replaceAll([QuestionsRoute()]);
      },
      openDashboard: () {
        context.router.replaceAll([const DashboardRoute()]);
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Assets.icons.iconCalora.svg(),
                    const SizedBox(height: 32),
                    VerifyCodeWidget(
                      controller: manager.controller,
                      resend: manager.resend,
                      resultCode: (data) {
                        if (data.length == 6) {
                          // manager.verify();
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: Button(
                        loading: state.loading,
                        onPressed: manager.verify,
                        child: Strings.doContinue.text(16, 20, 500).c(context.colors.textWhite),
                      ),
                    ),
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
