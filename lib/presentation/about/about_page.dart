import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Strings.aboutCalora.text(24, 32, 700),
          const SizedBox(height: 8),
          Strings.welcomeToHealthyLife.text(14, 16, 400),
          const SizedBox(height: 16),
          Strings.caloraAboutText.text(14, 16, 400).c(context.colors.textStrong),
          const SizedBox(height: 16),
          // Version row
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: context.colors.backgroundElevation,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Strings.version.text(14, 16, 400).c(context.colors.textStrong),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Strings.version.text(14, 16, 400);
                    }
                    final version = snapshot.data!.version;
                    final buildNumber = snapshot.data!.buildNumber;
                    return "$version+$buildNumber".text(14, 16, 400).c(context.colors.textStrong);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
