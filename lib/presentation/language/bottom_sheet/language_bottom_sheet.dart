import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/domain/model/language/language.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final current = Language.fromLocale(context.locale);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 24,
              height: 3,
              color: context.colors.strokeSoft,
            ),
          ),
          const SizedBox(height: 13),
          Strings.applicationLanguage.text(20, 24, 700),
          const SizedBox(height: 16),
          ...Language.values.map((lang) {
            final isSelected = lang == current;
            return ListTile(
              leading: lang.flag,
              title: lang.name.text(16, 20, 400),
              trailing: isSelected ? Assets.icons.icSingleCheck.svg() : null,
              onTap: () async {
                if (!isSelected) {
                  await context.setLocale(lang.locale);
                }
              },
            );
          }),
        ],
      ),
    );
  }
}
