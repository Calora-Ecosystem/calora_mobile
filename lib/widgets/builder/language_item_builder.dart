import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/domain/model/language/language.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class LanguageItem extends StatelessWidget {
  final Language language;
  final bool isChecked;
  final Function(Language) onTap;

  LanguageItem({
    required this.language,
    required this.isChecked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onTap.call(language);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.colors.backgroundBase,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              width: 1,
              color: isChecked
                  ? context.colors.strokeAccent
                  : context.colors.strokeSoft,
            ),
          ),
          child: Row(
            children: [
              _languageIcon(language, context),
              SizedBox(width: 12,),
              _currentText(language, context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _currentText(Language language, BuildContext context) {
    switch (language) {
      case Language.EN:
        return language.name.text(16, 16, 300).c(context.colors.textStrong);
      case Language.RU:
        return language.name.text(16, 16, 300).c(context.colors.textStrong);
      case Language.UZ:
        return language.name.text(16, 16, 300).c(context.colors.textStrong);
    }
  }

  Widget _languageIcon(Language language, BuildContext context) {
    switch (language) {
      case Language.EN:
        return Assets.icons.icEnFlag.svg();
      case Language.RU:
        return Assets.icons.icRuFlag.svg();
      case Language.UZ:
        return Assets.icons.icUzFlag.svg();
    }
  }
}
