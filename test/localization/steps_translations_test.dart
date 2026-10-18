import 'dart:io';

import 'package:calora/common/localization/safe_csv_asset_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final extra = SafeCsvAssetLoader.parserFor(
    File('assets/localization/translations_extra.csv').readAsStringSync(),
  );
  final sheet = SafeCsvAssetLoader.parserFor(
    File('assets/localization/translations.csv').readAsStringSync(),
  );
  const locales = ['en_US', 'uz_UZ', 'ru_RU'];

  test('every extra key is translated in every language', () {
    final keys = extra.getLanguageMap('en_US').keys;
    expect(keys, isNotEmpty);
    for (final locale in locales) {
      final map = extra.getLanguageMap(locale);
      for (final key in keys) {
        final value = map[key];
        expect(value, isA<String>(), reason: '$key missing in $locale');
        expect(
          (value as String).trim(),
          isNotEmpty,
          reason: '$key empty in $locale',
        );
      }
    }
  });

  test('placeholders match across languages', () {
    final placeholder = RegExp(r'\{\w+\}');
    final english = extra.getLanguageMap('en_US');
    for (final locale in locales) {
      final map = extra.getLanguageMap(locale);
      english.forEach((key, value) {
        final expected = placeholder
            .allMatches(value as String)
            .map((m) => m[0])
            .toSet();
        final actual = placeholder
            .allMatches(map[key] as String)
            .map((m) => m[0])
            .toSet();
        expect(actual, expected, reason: '$key/$locale');
      });
    }
  });

  test('extra keys do not shadow sheet keys', () {
    final sheetKeys = sheet.getLanguageMap('en_US').keys.toSet();
    final overlap = extra
        .getLanguageMap('en_US')
        .keys
        .where(sheetKeys.contains);
    expect(overlap, isEmpty);
  });

  test('locale code key matches the column language', () {
    expect(extra.getLanguageMap('en_US')['steps_locale_code'], 'en');
    expect(extra.getLanguageMap('uz_UZ')['steps_locale_code'], 'uz');
    expect(extra.getLanguageMap('ru_RU')['steps_locale_code'], 'ru');
  });
}
