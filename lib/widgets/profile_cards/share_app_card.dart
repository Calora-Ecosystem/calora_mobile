import 'package:calora/common/constants/app_links.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/util/share_origin.dart';
import 'package:calora/common/widgets/snack_bar/custom_snack_bar.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// Profile → "Share the app": opens the share sheet with the download link
/// alone — no invite code, no message.
class ShareAppCard extends StatelessWidget {
  const ShareAppCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Container(
          decoration: BoxDecoration(
            color: colors.backgroundElevation,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(4),
          child: Icon(
            Icons.ios_share_rounded,
            size: 20,
            color: colors.accentSub,
          ),
        ),
        title: 'share_app_title'.tr().text(14, 16, 400).c(colors.textStrong),
        subtitle: appDownloadLink
            .replaceFirst('https://', '')
            .text(12, 16, 400)
            .c(colors.textSub),
        trailing: Assets.icons.arrowRight.svg(),
        onTap: () => _share(context),
      ),
    );
  }

  Future<void> _share(BuildContext context) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          uri: Uri.parse(appDownloadLink),
          sharePositionOrigin: shareOrigin(context),
        ),
      );
    } catch (_) {
      if (context.mounted) {
        CustomSnackBar.show(context, 'something_went_wrong'.tr());
      }
    }
  }
}
