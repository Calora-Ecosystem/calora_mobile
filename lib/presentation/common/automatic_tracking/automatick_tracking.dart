import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

void showAutomaticTrackingSheet(
  BuildContext context, {
  required String title,
  required VoidCallback onConnectTap,
  required Widget secondAsset,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            title.text(24, 32, 700),
            const SizedBox(height: 8),
            Strings.automaticTrackerSubtitle
                .text(14, 16, 400)
                .c(context.colors.textPrimary),
            const SizedBox(height: 16),

            Text(
              Strings.garminIntro,
              style: const TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 12),
            Text(Strings.requirementsLabel),
            Text(Strings.garminReqDevice),
            Text(Strings.garminReqApp),
            Text(Strings.garminReqInternet),
            Text(Strings.garminReqCaloraVersion),

            const SizedBox(height: 12),
            Text(Strings.howToConnect),
            Text(Strings.garminStep1),
            Text(Strings.garminStep2),
            Text(Strings.garminStep3),
            Text(Strings.garminStep4),
            Text(Strings.garminStep5),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildIconButton(
                  Assets.images.caloraLogo.image(),
                  'Calora',
                  context,
                ),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.colors.backgroundElevation6,

                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Assets.icons.refresh.svg(),
                ),
                _buildIconButton(secondAsset, title, context),
              ],
            ),

            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                onConnectTap();
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: context.colors.accentSub,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Strings.connect
                    .text(16, 20, 500)
                    .c(context.colors.white)
                    .copyWith(textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildIconButton(Widget assetPath, String label, BuildContext context) {
  return Column(
    children: [
      Container(
        height: 100,
        width: 100,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: assetPath,
      ),
      const SizedBox(height: 6),
      label.text(14, 16, 400).c(context.colors.textPrimary),
    ],
  );
}
