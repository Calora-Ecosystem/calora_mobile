import 'package:calora/common/di/injection.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/domain/model/language/language.dart';
import 'package:calora/domain/repo/common/common_repo.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final current = Language.fromLocale(context.locale);

    // The host showModalBottomSheet already paints the white rounded
    // background, so here we only lay out the content — with a bottom
    // safe-area inset so the last row never sits under the gesture bar.
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.strokeSoft,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Strings.applicationLanguage.text(20, 24, 700),
            const SizedBox(height: 8),
            ...Language.values.map((lang) {
              final isSelected = lang == current;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                visualDensity: const VisualDensity(vertical: -1),
                leading: SizedBox(width: 32, height: 32, child: lang.flag),
                title: lang.name.text(16, 20, 500),
                trailing: isSelected
                    ? Assets.icons.icSingleCheck.svg()
                    : Icon(Icons.circle_outlined,
                        size: 20, color: context.colors.strokeSoft),
                onTap: () async {
                  if (isSelected) return;
                  // Persist BEFORE anything else can fire a request — the
                  // TokenInterceptor reads the same key to set
                  // `Accept-Language` on outgoing requests, so racing the
                  // SharedPreferences write would send the old locale.
                  await getIt<CommonRepo>().setSelectedLanguage(lang);
                  if (!context.mounted) return;
                  // Update EasyLocalization so Strings.* re-translate.
                  await context.setLocale(lang.locale);
                  if (context.mounted) Navigator.of(context).pop();
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
