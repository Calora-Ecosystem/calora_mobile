import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

void showLanguageBottomSheet(BuildContext context) {
  final currentLocale = context.locale;
  final languages = [
    {
      "code": "uz",
      "name": "O'zbekcha",
      "flag": Assets.icons.icUzFlag.svg(),
      "locale": const Locale("uz", "UZ"),
    },
    // {"code": "uzCyr", "name": "Ўзбекча", "flag": "🇺🇿", "locale": const Locale("uz", "CYR")},
    {
      "code": "ru",
      "name": "Русский",
      "flag": Assets.icons.icRuFlag.svg(),
      "locale": const Locale("ru", "RU"),
    },
    {
      "code": "en",
      "name": "English",
      "flag": Assets.icons.icEnFlag.svg(),
      "locale": const Locale("en", "US"),
    },
  ];

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 24, height: 3, color: context.colors.strokeSoft)),
            SizedBox(height: 13),
            Strings.applicationLanguage.text(20, 24, 700),
            SizedBox(height: 16),
            ...languages.map((lang) {
              final locale = lang["locale"] as Locale;
              return ListTile(
                leading: lang["flag"] as Widget,
                title: (lang["name"] as String).text(16, 20, 400),
                trailing: currentLocale == locale ? Assets.icons.icSingleCheck.svg() : null,
                onTap: () async {
                  await context.setLocale(locale);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      );
    },
  );
}
