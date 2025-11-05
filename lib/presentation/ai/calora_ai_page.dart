import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/presentation/ai/management/calora_ai_management.dart';
import 'package:calora/presentation/ai/management/calora_ai_manager.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/common/confirm/confirm_page.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

@RoutePage()
class CaloraAiPage extends Managed<CaloraAiManager, CaloraAiState, CaloraAiEffect> {
  @override
  void listener(BuildContext context, CaloraAiManager manager, CaloraAiEffect effect) {
    effect.mapOrNull(
      showConfirmDialog: (value) => _showConfirmDialog(context, manager),
      navigateToCamera: (_) => context.router.push(const CaloraCameraRoute()),
    );
    super.listener(context, manager, effect);
  }

  @override
  Widget builder(BuildContext context, CaloraAiManager manager, CaloraAiState state) {
    return Scaffold(
      appBar: AppBar(backgroundColor: context.colors.white, elevation: 0, scrolledUnderElevation: 0),
      backgroundColor: context.colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 100, width: 100, child: Assets.images.ai.image()),
                const SizedBox(height: 4),
                Strings.caloraAi.text(16, 20, 500).c(context.colors.textStrong),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.colors.backgroundElevation,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Assets.icons.informationCircleBlue.svg(),
                      const SizedBox(width: 8),
                      Expanded(child: Strings.takeAPicture.text(14, 18, 400).c(context.colors.brightBlue)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Assets.images.thisIsLottie.image(),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Strings.takePictureOfYourFaceLikeThis.text(16, 20, 500).c(context.colors.textStrong),
                ),
                const SizedBox(height: 12),
                buildDotTextRow(context, Strings.standInFrontOfTheCamera),
                const SizedBox(height: 12),
                buildDotTextRow(context, Strings.letYourFaceBeFullyVisible),
                const SizedBox(height: 12),
                buildDotTextRow(context, Strings.makeSureTheLightingIsGood),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: Button(onPressed: () => manager.openConfirmPage(), text: Strings.next),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildDotTextRow(BuildContext context, String text) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: context.colors.accentSub, borderRadius: BorderRadius.circular(20)),
        ),
        const SizedBox(width: 8),
        Expanded(child: text.text(14, 18, 400).c(context.colors.textSub)),
      ],
    );
  }

  void _showConfirmDialog(BuildContext context, CaloraAiManager manager) {
    showDialog(
      context: context,
      builder: (_) => ConfirmPage(
        onConfirm: () => manager.requestCameraPermission(),
        onCancel: () {},
        confirmBackgroundColor: context.colors.accentSub,
        confirmTextColor: context.colors.white,
        cancelText: Strings.rejection,
        confirmText: Strings.allow,
        cancelTextColor: context.colors.textStrong,
        title: Strings.allowAccessToYourCamera,
      ),
    );
  }
}
