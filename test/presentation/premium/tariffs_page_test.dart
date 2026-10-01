import 'dart:io';

import 'package:calora/common/gen/fonts.gen.dart';
import 'package:calora/common/localization/safe_csv_asset_loader.dart';
import 'package:calora/domain/model/premium/premium_plan_model.dart';
import 'package:calora/domain/repo/premium/premium_repo.dart';
import 'package:calora/presentation/app/theme/colors.dart';
import 'package:calora/presentation/premium/tariffs_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
// EasyLocalization.ensureInitialized reads the saved locale from it.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';

/// Lays the tariffs page out on a small phone with the real Uzbek / Russian
/// strings and walks every plan — any overflow fails the test. Prices come
/// from the (fake) backend packages the dashboard manages.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final byLocale = <String, Map<String, dynamic>>{};
  final repo = _FakePremiumRepo();

  setUp(() {
    repo.regular = const [
      PremiumPlanModel(id: 1, duration: 1, fee: 49000, isActive: true),
      PremiumPlanModel(id: 2, duration: 12, fee: 399000, isActive: true),
    ];
    repo.family = const [
      PremiumPlanModel(id: 3, duration: 1, fee: 70000, isFamily: true),
    ];
  });

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    GetIt.instance
      ..registerSingleton(DefaultThemeColors())
      ..registerSingleton<PremiumRepo>(repo);

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
              home: const TariffsPage(),
            ),
          ),
        ),
      );
      for (
        var i = 0;
        i < 50 && find.byType(TariffsPage).evaluate().isEmpty;
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
    if (const bool.fromEnvironment('TF_GOLDEN')) {
      await expectLater(
        find.byType(TariffsPage),
        matchesGoldenFile('goldens/$name.png'),
      );
    }
  }

  for (final locale in ['uz_UZ', 'ru_RU']) {
    testWidgets('tariffs page lays out ($locale)', (tester) async {
      await pump(tester, locale);
      await shot(tester, '${locale}_yearly');

      // Family: two people for 70 000 instead of 98 000.
      final family = find.text(locale == 'uz_UZ' ? 'Oila' : 'Семейный');
      await tester.ensureVisible(family);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(family);
      await tester.pump();
      // The family price story runs ~1.7 s once it is on screen.
      await tester.pump(const Duration(seconds: 2));
      expect(find.textContaining('70 000'), findsWidgets);
      expect(find.textContaining('98 000'), findsWidgets);
      expect(find.textContaining('28 000'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -140));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await shot(tester, '${locale}_family');

      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await shot(tester, '${locale}_features');
    });
  }

  testWidgets('prices follow the dashboard packages', (tester) async {
    repo.regular = const [
      PremiumPlanModel(id: 1, duration: 1, fee: 55000),
      PremiumPlanModel(id: 2, duration: 12, fee: 450000),
    ];
    repo.family = const [
      PremiumPlanModel(id: 3, duration: 1, fee: 80000, isFamily: true),
    ];
    await pump(tester, 'uz_UZ');
    expect(tester.takeException(), isNull);
    expect(find.textContaining('450 000'), findsWidgets);
    expect(find.textContaining('55 000'), findsWidgets);
    expect(find.textContaining('80 000'), findsWidgets);
    expect(find.textContaining('49 000'), findsNothing);
  });

  testWidgets('no family package → no family row', (tester) async {
    repo.family = const [];
    await pump(tester, 'uz_UZ');
    expect(tester.takeException(), isNull);
    expect(find.text('Oila'), findsNothing);
    expect(find.textContaining('399 000'), findsWidgets);
  });

  testWidgets('a backend without the family flag never shows a family row', (
    tester,
  ) async {
    // An old backend ignores `family=true` and returns the regular list.
    repo.family = repo.regular;
    await pump(tester, 'uz_UZ');
    expect(find.text('Oila'), findsNothing);
  });
}

class _FakePremiumRepo implements PremiumRepo {
  List<PremiumPlanModel> regular = const [];
  List<PremiumPlanModel> family = const [];

  @override
  Future<List<PremiumPlanModel>> getPremiumPlans({bool family = false}) async =>
      family ? this.family : regular;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MapLoader extends AssetLoader {
  final Map<String, dynamic> map;

  const _MapLoader(this.map);

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => map;
}
