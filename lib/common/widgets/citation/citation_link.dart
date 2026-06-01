import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' show launchUrl, LaunchMode;

class CitationLink extends StatelessWidget {
  final String url;
  final String label;

  const CitationLink({super.key, required this.url, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.open_in_new, size: 12, color: context.colors.textSub),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '${'source_label'.tr()}: $label',
                style: TextStyle(
                  fontSize: 11,
                  height: 14 / 11,
                  color: context.colors.textSub,
                  decoration: TextDecoration.underline,
                  decorationColor: context.colors.textSub,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
