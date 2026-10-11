import 'dart:io';

import 'package:calora/common/enums/subscription_plan_type.dart';
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

import '../../fixtures/premium_plans.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final byLocale = <String, Map<String, dynamic>>{};
  final repo = _FakePremiumRepo();

  setUp(() {
    repo.plans = PremiumPlanModel.listFromJson(backendPlans);
    repo.calls = 0;
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

      final family = find.text(
        locale == 'uz_UZ'
            ? 'Ikki kishi uchun bitta obuna'
            : 'Одна подписка на двоих',
      );
      await tester.ensureVisible(family);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(family);
      await tester.pump();
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

  testWidgets('groups the backend list into Premium and Family', (
    tester,
  ) async {
    await pump(tester, 'uz_UZ');
    expect(tester.takeException(), isNull);
    expect(repo.calls, 1);
    expect(find.text('Premium'), findsOneWidget);
    expect(find.text('Oila'), findsOneWidget);
    expect(find.text('Cheksiz AI skanlar'), findsOneWidget);
    expect(find.byKey(const ValueKey(399000)), findsOneWidget);
    expect(find.byKey(const ValueKey(49000)), findsOneWidget);
    expect(find.byKey(const ValueKey(70000)), findsOneWidget);
    expect(find.byKey(const ValueKey(0)), findsNothing);
  });

  testWidgets('prices follow the dashboard packages', (tester) async {
    repo.plans = const [
      PremiumPlanModel(id: 1, fee: 55000),
      PremiumPlanModel(id: 2, duration: 12, fee: 450000),
      PremiumPlanModel(id: 3, type: SubscriptionPlanType.family, fee: 80000),
    ];
    await pump(tester, 'uz_UZ');
    expect(tester.takeException(), isNull);
    expect(find.textContaining('450 000'), findsWidgets);
    expect(find.textContaining('55 000'), findsWidgets);
    expect(find.textContaining('80 000'), findsWidgets);
    expect(find.textContaining('49 000'), findsNothing);
  });

  testWidgets('no family package → no family group', (tester) async {
    repo.plans = repo.plans.where((plan) => !plan.isFamily).toList();
    await pump(tester, 'uz_UZ');
    expect(tester.takeException(), isNull);
    expect(find.text('Oila'), findsNothing);
    expect(find.textContaining('399 000'), findsWidgets);
  });

  testWidgets('only Free on the backend → retry instead of a price', (
    tester,
  ) async {
    repo.plans = repo.plans.where((plan) => plan.type.isFree).toList();
    await pump(tester, 'uz_UZ');
    expect(tester.takeException(), isNull);
    expect(find.text('Premium'), findsNothing);
    expect(find.byType(TextButton), findsWidgets);
  });
}

class _FakePremiumRepo implements PremiumRepo {
  List<PremiumPlanModel> plans = const [];
  int calls = 0;

  @override
  Future<List<PremiumPlanModel>> getPremiumPlans() async {
    calls++;
    return plans;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MapLoader extends AssetLoader {
  final Map<String, dynamic> map;

  const _MapLoader(this.map);

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => map;
}
