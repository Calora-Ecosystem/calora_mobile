import 'package:calora/domain/model/language/language.dart';
import 'package:calora/widgets/builder/language_item_builder.dart';
import 'package:flutter/cupertino.dart';

class LanguageWidget extends StatelessWidget {
  final List<Language> languages;
  final Language selectedLanguage;
  final Function(Language) onLanguageSelected;

  const LanguageWidget({
    super.key,
    required this.languages,
    required this.selectedLanguage,
    required this.onLanguageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: languages.length,
      itemBuilder: (context, index) {
        final language = languages[index];
        final isSelected = selectedLanguage == language;
        return LanguageItem(
          language: language,
          isChecked: isSelected,
          onTap: (data) => onLanguageSelected(data),
        );
      },
    );
  }
}
