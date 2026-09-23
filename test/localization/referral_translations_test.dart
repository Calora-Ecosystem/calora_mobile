import 'dart:io';

import 'package:easy_localization_loader/easy_localization_loader.dart';
import 'package:flutter_test/flutter_test.dart';

/// Parses the translations file the same way [SafeCsvAssetLoader] does and
/// checks the referral / wallet keys exist in every language with their
/// placeholders — a broken row would show raw keys in the app.
void main() {
  final raw = File(
    'assets/localization/translations.csv',
  ).readAsStringSync().replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final parser = CSVParser(
    raw,
    fieldDelimiter: ',',
    eol: '\n',
    useAutodetect: false,
  );

  const required = {
    'referral_hero_title': ['{friends}', '{period}'],
    'referral_hero_sub': <String>[],
    'referral_progress_hint': ['{left}'],
    'referral_share_text': ['{code}', '{percent}', '{link}'],
    'referral_step_3': ['{friends}', '{period}'],
    'referral_step_4': ['{percent}'],
    'referral_period_months': ['{count}'],
    'invite_code_hint': <String>[],
    'coin_earn_rule': ['{steps}'],
    'coin_earn_limit': ['{coins}'],
  };

  for (final locale in ['en_US', 'uz_UZ', 'ru_RU']) {
    test('referral and wallet keys in $locale', () {
      final map = parser.getLanguageMap(locale);
      required.forEach((key, placeholders) {
        final value = map[key];
        expect(value, isA<String>(), reason: '$key missing in $locale');
        for (final p in placeholders) {
          expect(value as String, contains(p), reason: '$key/$locale lacks $p');
        }
      });
    });
  }
}
