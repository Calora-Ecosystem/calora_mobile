import 'package:calora/common/constants/app_links.dart';
import 'package:calora/common/localization/safe_csv_asset_loader.dart';
import 'package:calora/common/util/invite_share_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';

/// Invite messages are translated when the user taps share, so switching the
/// interface language switches the message — and every message carries the
/// plain download link, nothing else.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const locales = [Locale('uz', 'UZ'), Locale('ru', 'RU'), Locale('en', 'US')];
  final byLocale = <String, Map<String, dynamic>>{};

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    final loader = SafeCsvAssetLoader();
    for (final locale in locales) {
      byLocale['$locale'] = await loader.load(
        'assets/localization/translations.csv',
        locale,
      );
    }
  });

  String fill(dynamic template, Map<String, String> args) => args.entries.fold(
    template as String,
    (text, arg) => text.replaceAll('{${arg.key}}', arg.value),
  );

  List<String?> links(String message) =>
      RegExp(r'https?://\S+').allMatches(message).map((m) => m[0]).toList();

  testWidgets('invite messages follow the interface language', (tester) async {
    late BuildContext appContext;
    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: locales,
          path: 'unused',
          assetLoader: _MapLoader(byLocale),
          startLocale: locales.first,
          saveLocale: false,
          child: Builder(
            builder: (context) => MaterialApp(
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              home: Builder(
                builder: (context) {
                  appContext = context;
                  return const Text('ready');
                },
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 50 && find.text('ready').evaluate().isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pump();
      }
    });

    final groupMessages = <String>{};
    final referralMessages = <String>{};
    for (final locale in locales) {
      await tester.runAsync(() => appContext.setLocale(locale));
      await tester.pumpAndSettle();
      final t = byLocale['$locale']!;

      final group = groupInviteShareText(groupName: 'Ofis', code: 'CALK7M2Q');
      expect(
        group,
        [
          fill(t['share_group_invite'], {'name': 'Ofis'}),
          fill(t['share_group_code'], {'code': 'CALK7M2Q'}),
          fill(t['share_app_download'], {'link': appDownloadLink}),
        ].join('\n\n'),
        reason: '$locale',
      );
      expect(links(group), [appDownloadLink], reason: '$locale');

      final referral = referralShareText(code: 'CALORAK7M2QX', percent: 10);
      expect(
        referral,
        fill(t['referral_share_text'], {
          'code': 'CALORAK7M2QX',
          'percent': '10',
          'link': appDownloadLink,
        }),
        reason: '$locale',
      );
      expect(links(referral), [appDownloadLink], reason: '$locale');

      groupMessages.add(group);
      referralMessages.add(referral);
    }
    expect(groupMessages, hasLength(locales.length));
    expect(referralMessages, hasLength(locales.length));
  });
}

class _MapLoader extends AssetLoader {
  final Map<String, Map<String, dynamic>> byLocale;

  const _MapLoader(this.byLocale);

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      byLocale['$locale']!;
}
