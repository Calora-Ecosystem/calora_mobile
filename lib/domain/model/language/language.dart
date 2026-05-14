import 'package:calora/common/gen/assets.gen.dart';
import 'package:flutter/material.dart';

enum Language {
  UZ,
  EN,
  RU;

  static Language fromName(String name) {
    return Language.values.firstWhere(
      (element) => element.name == name,
      orElse: () => Language.UZ,
    );
  }

  static Language fromLocale(Locale locale) {
    return Language.values.firstWhere(
      (element) => element.locale.languageCode == locale.languageCode,
      orElse: () => Language.UZ,
    );
  }

  String get name {
    switch (this) {
      case Language.UZ:
        return 'Oʻzbekcha';
      case Language.EN:
        return 'English';
      case Language.RU:
        return 'Русский';
    }
  }

  Locale get locale {
    switch (this) {
      case Language.EN:
        return const Locale('en', 'US');
      case Language.UZ:
        return const Locale('uz', 'UZ');
      case Language.RU:
        return const Locale('ru', 'RU');
    }
  }

  String get code {
    switch (this) {
      case Language.UZ:
        return 'UZ';
      case Language.EN:
        return 'ENG';
      case Language.RU:
        return 'RU';
    }
  }

  Widget get flag {
    switch (this) {
      case Language.UZ:
        return Assets.icons.icUzFlag.svg();
      case Language.EN:
        return Assets.icons.icEnFlag.svg();
      case Language.RU:
        return Assets.icons.icRuFlag.svg();
    }
  }
}
