import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/domain/model/verification/verification.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/verify/verify_code_widget.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

import 'management/verify_management.dart';
import 'management/verify_manager.dart';

@RoutePage()
class VerifyPage extends Managed<VerifyManager, VerifyState, VerifyEffect> {
  final Verification verification;

  VerifyPage({super.key, required this.verification});

  @override
  void init(context, manager) {
    manager.setVerification(verification);
  }

  @override
  void listener(context, manager, effect) {
    effect.when(() {
      _openInputNamePage(context);
    });
  }

  @override
  Widget builder(context, manager, state) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Assets.icons.background.image(fit: BoxFit.fill)),
          SafeArea(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Assets.icons.iconCalora.svg(),
                    SizedBox(height: 32),
                    VerifyCodeWidget(
                      resend: manager.resend,
                      resultCode: (data) {
                        manager.setVerificationCode(data);
                      },
                    ),
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

  void _openInputNamePage(BuildContext context) {
    context.router.replace(DashboardRoute());
  }
}
