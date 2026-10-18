import 'dart:io';

import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/fonts.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/localization/safe_csv_asset_loader.dart';
import 'package:calora/presentation/app/theme/colors.dart';
import 'package:calora/presentation/coins/widgets/coin_balance_chip.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';

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

    final flutterRoot = Platform.environment['FLUTTER_ROOT'];
    final icons = File(
      '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (flutterRoot != null && icons.existsSync()) {
      await (FontLoader('MaterialIcons')..addFont(
            Future.value(ByteData.sublistView(icons.readAsBytesSync())),
          ))
          .load();
    }
  });

  final loaders = <String, _MapLoader>{};

  Widget app(String locale, int? balance, VoidCallback onTap) {
    final parts = locale.split('_');
    return EasyLocalization(
      supportedLocales: [Locale(parts[0], parts[1])],
      path: 'unused',
      assetLoader: loaders.putIfAbsent(
        locale,
        () => _MapLoader(byLocale[locale]!),
      ),
      startLocale: Locale(parts[0], parts[1]),
      saveLocale: false,
      child: Builder(
        builder: (context) => MaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: Scaffold(
            backgroundColor: DefaultThemeColors().softGray,
            body: Padding(
              padding: const EdgeInsets.only(top: 42, left: 20, right: 20),
              child: Row(
                children: [
                  Expanded(child: Strings.steps.text(32, 36, 700)),
                  const SizedBox(width: 12),
                  CoinBalanceChip(balance: balance, onTap: onTap),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> pump(
    WidgetTester tester,
    String locale, {
    required int? balance,
    VoidCallback? onTap,
  }) async {
    tester.view.physicalSize = const Size(320 * 3, 120 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.runAsync(() async {
      await tester.pumpWidget(app(locale, balance, onTap ?? () {}));
      for (
        var i = 0;
        i < 50 && find.byType(CoinBalanceChip).evaluate().isEmpty;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pump();
      }
    });
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> shot(WidgetTester tester, String name) async {
    expect(tester.takeException(), isNull, reason: name);
    if (const bool.fromEnvironment('TF_GOLDEN')) {
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/$name.png'),
      );
    }
  }

  for (final locale in ['uz_UZ', 'ru_RU']) {
    testWidgets('header fits while the balance loads ($locale)', (
      tester,
    ) async {
      await pump(tester, locale, balance: null);
      expect(find.text('0'), findsNothing);
      await shot(tester, 'chip_${locale}_loading');
    });

    for (final balance in [48, 1234567]) {
      testWidgets('header fits a $balance coin balance ($locale)', (
        tester,
      ) async {
        await pump(tester, locale, balance: balance);
        expect(find.text(balance == 48 ? '48' : '1 234 567'), findsOneWidget);
        await shot(tester, 'chip_${locale}_$balance');
      });
    }
  }

  testWidgets('tapping the chip opens the wallet', (tester) async {
    var taps = 0;
    await pump(tester, 'uz_UZ', balance: 12, onTap: () => taps++);
    await tester.tap(find.byType(CoinBalanceChip));
    expect(taps, 1);
  });

  testWidgets('a balance change counts up to the new value', (tester) async {
    await pump(tester, 'uz_UZ', balance: 10);
    await tester.pumpWidget(app('uz_UZ', 20, () {}));
    await tester.pump(const Duration(milliseconds: 150));
    final shown = tester
        .widget<Text>(
          find.descendant(
            of: find.byType(CoinBalanceChip),
            matching: find.byType(Text),
          ),
        )
        .data!;
    expect(int.parse(shown), inExclusiveRange(10, 20));
    await tester.pumpAndSettle();
    expect(find.text('20'), findsOneWidget);
  });
}

class _MapLoader extends AssetLoader {
  final Map<String, dynamic> map;

  const _MapLoader(this.map);

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => map;
}
