import 'dart:io';

import 'package:calora/common/gen/fonts.gen.dart';
import 'package:calora/common/localization/safe_csv_asset_loader.dart';
import 'package:calora/presentation/app/theme/colors.dart';
import 'package:calora/widgets/meals/free_scan_banner.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
// EasyLocalization.ensureInitialized reads the saved locale from it.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';

/// Lays the free-scan card (every state) and the "scans are over" sheet out
/// on a small phone with the real Uzbek / Russian strings — any overflow
/// fails the test. `--dart-define=FS_GOLDEN=true --update-goldens` renders
/// previews.
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

  Future<void> pump(WidgetTester tester, String locale, Widget child) async {
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
              home: Scaffold(
                key: const ValueKey('screen'),
                backgroundColor: Colors.white,
                body: child,
              ),
            ),
          ),
        ),
      );
      for (
        var i = 0;
        i < 50 && find.byKey(const ValueKey('screen')).evaluate().isEmpty;
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
    if (const bool.fromEnvironment('FS_GOLDEN')) {
      await expectLater(
        find.byKey(const ValueKey('screen')),
        matchesGoldenFile('goldens/$name.png'),
      );
    }
  }

  for (final locale in ['uz_UZ', 'ru_RU']) {
    testWidgets('free scan card and sheet lay out ($locale)', (tester) async {
      await pump(
        tester,
        locale,
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                for (final left in [5, 3, 1, 0]) ...[
                  FreeScanCard(remaining: left, limit: 5, onTap: () {}),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      );
      await shot(tester, 'fs_${locale}_cards');

      await pump(
        tester,
        locale,
        Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Colors.white,
            child: FreeScansOverSheet(limit: 5, onPremium: () {}),
          ),
        ),
      );
      await shot(tester, 'fs_${locale}_sheet');
    });
  }
}

class _MapLoader extends AssetLoader {
  final Map<String, dynamic> map;

  const _MapLoader(this.map);

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => map;
}
