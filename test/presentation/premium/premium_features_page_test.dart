import 'dart:io';

import 'package:calora/common/gen/fonts.gen.dart';
import 'package:calora/common/localization/safe_csv_asset_loader.dart';
import 'package:calora/presentation/app/theme/colors.dart';
import 'package:calora/presentation/premium/premium_features_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
// EasyLocalization.ensureInitialized reads the saved locale from it.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';

/// Lays the premium page out on a small phone with the real Uzbek / Russian
/// strings and scrolls through it — any overflow fails the test.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final byLocale = <String, Map<String, dynamic>>{};

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    GetIt.instance.registerSingleton(DefaultThemeColors());

    final loader = SafeCsvAssetLoader();
    for (final locale in ['uz_UZ', 'ru_RU']) {
      final parts = locale.split('_');
      byLocale[locale] = await loader.load(
        'assets/localization/translations.csv',
        Locale(parts[0], parts[1]),
      );
    }

    for (final font in ['Regular', 'Medium', 'Bold']) {
      final bytes = File('assets/fonts/Inter-$font.ttf').readAsBytesSync();
      await (FontLoader(
        FontFamily.inter,
      )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
    }
  });

  Future<void> pump(WidgetTester tester, String locale) async {
    tester.view.physicalSize = const Size(360 * 3, 740 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final parts = locale.split('_');
    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: [Locale(parts[0], parts[1])],
          path: 'unused',
          assetLoader: _MapLoader(byLocale[locale]!),
          startLocale: Locale(parts[0], parts[1]),
          saveLocale: false,
          child: Builder(
            builder: (context) => MaterialApp(
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              home: const PremiumFeaturesPage(),
            ),
          ),
        ),
      );
      for (
        var i = 0;
        i < 50 && find.byType(PremiumFeaturesPage).evaluate().isEmpty;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pump();
      }
    });
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> shot(WidgetTester tester, String name) async {
    expect(tester.takeException(), isNull, reason: name);
    if (const bool.fromEnvironment('PW_GOLDEN')) {
      await expectLater(
        find.byType(PremiumFeaturesPage),
        matchesGoldenFile('goldens/$name.png'),
      );
    }
  }

  for (final locale in ['uz_UZ', 'ru_RU']) {
    testWidgets('premium page lays out ($locale)', (tester) async {
      await pump(tester, locale);
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await shot(tester, 'pw_${locale}_hero');
      for (var i = 1; i <= 3; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -620));
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        await shot(tester, 'pw_${locale}_$i');
      }
    });
  }
}

class _MapLoader extends AssetLoader {
  final Map<String, dynamic> map;

  const _MapLoader(this.map);

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => map;
}
