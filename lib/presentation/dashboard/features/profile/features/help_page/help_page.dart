import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void showHelpBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: context.colors.white,
    isScrollControlled: true,
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Strings.helpDesk.text(24, 32, 700),
            const SizedBox(height: 8),
            Strings.writeHelp.text(14, 16, 400).c(context.colors.textStrong),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final url = Uri.parse("https://t.me/N0d1rbe");
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: context.colors.backgroundElevation,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Assets.icons.telegram.svg(),
                          const SizedBox(height: 4),
                          'Telegram'.text(12, 16, 500),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final gmailUri = Uri.parse(
                        'https://mail.google.com/mail/?view=cm&fs=1&to=hasanovnodir2005@gmail.com',
                      );
                      if (await canLaunchUrl(gmailUri)) {
                        await launchUrl(gmailUri, mode: LaunchMode.externalApplication);
                      }
                    },

                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: context.colors.backgroundElevation,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Assets.icons.mail.svg(),
                          const SizedBox(height: 4),
                          'Mail'.text(12, 16, 500),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
