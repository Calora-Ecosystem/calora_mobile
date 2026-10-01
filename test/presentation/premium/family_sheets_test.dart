import 'dart:io';

import 'package:calora/common/gen/fonts.gen.dart';
import 'package:calora/common/localization/safe_csv_asset_loader.dart';
import 'package:calora/domain/model/premium/family_code.dart';
import 'package:calora/domain/repo/premium/premium_repo.dart';
import 'package:calora/presentation/app/theme/colors.dart';
import 'package:calora/presentation/premium/family/family_code_sheet.dart';
import 'package:calora/presentation/premium/family/family_redeem_sheet.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
// EasyLocalization.ensureInitialized reads the saved locale from it.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';

/// Lays the family-plan sheets out on a small phone with the real Uzbek /
/// Russian strings (any overflow fails), and checks the redeem errors.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final byLocale = <String, Map<String, dynamic>>{};
  final repo = _FakePremiumRepo();

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

  Future<void> pump(
    WidgetTester tester,
    String locale,
    Widget sheet, {
    bool reduceMotion = false,
  }) async {
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
              theme: ThemeData(fontFamily: FontFamily.inter),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(disableAnimations: reduceMotion),
                child: child!,
              ),
              home: Scaffold(
                body: SafeArea(child: SingleChildScrollView(child: sheet)),
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 50 && find.byWidget(sheet).evaluate().isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pump();
      }
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  String tr(String locale, String key) => byLocale[locale]![key] as String;

  Future<void> shot(WidgetTester tester, String name) async {
    expect(tester.takeException(), isNull, reason: name);
    if (const bool.fromEnvironment('FAMILY_GOLDEN')) {
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/family_$name.png'),
      );
    }
  }

  for (final locale in ['uz_UZ', 'ru_RU']) {
    testWidgets('code sheet shows an active code ($locale)', (tester) async {
      repo.codes = [
        FamilyCode(code: 'FAMILY-AB12CD', expireAt: DateTime(2026, 10, 31)),
      ];
      final semantics = tester.ensureSemantics();
      await pump(tester, locale, const FamilyCodeSheet());
      // Mid-story: the ticket is decoding, nothing may overflow.
      await tester.pump(const Duration(milliseconds: 600));
      await shot(tester, '${locale}_code_mid');
      // The whole story: ticket flies over, code decodes, steps slide in.
      await tester.pump(const Duration(seconds: 3));

      await shot(tester, '${locale}_code');
      expect(find.bySemanticsLabel('FAMILY-AB12CD'), findsOneWidget);
      expect(find.text(tr(locale, 'family_code_copy')), findsOneWidget);
      expect(find.text(tr(locale, 'family_code_send')), findsOneWidget);
      expect(find.textContaining('31.10.2026'), findsOneWidget);

      // Tap the ticket: copied, confirmed in place.
      await tester.tap(find.bySemanticsLabel('FAMILY-AB12CD'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(tr(locale, 'copied')), findsOneWidget);
      await shot(tester, '${locale}_code_copied');
      await tester.pump(const Duration(seconds: 2));
      expect(find.text(tr(locale, 'family_code_copy')), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('code sheet without motion is final at once ($locale)', (
      tester,
    ) async {
      repo.codes = [
        FamilyCode(code: 'FAMILY-AB12CD', expireAt: DateTime(2026, 10, 31)),
      ];
      final semantics = tester.ensureSemantics();
      await pump(tester, locale, const FamilyCodeSheet(), reduceMotion: true);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel('FAMILY-AB12CD'), findsOneWidget);
      expect(find.text(tr(locale, 'family_code_how_3')), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('code sheet shows who redeemed it ($locale)', (tester) async {
      repo.codes = [
        const FamilyCode(
          code: 'FAMILY-AB12CD',
          status: FamilyCodeStatus.redeemed,
          redeemedBy: 'Vali',
        ),
      ];
      await pump(tester, locale, const FamilyCodeSheet());
      await tester.pump(const Duration(seconds: 3));

      await shot(tester, '${locale}_redeemed');
      expect(find.textContaining('Vali'), findsOneWidget);
      // Nothing left to share once it's used.
      expect(find.text(tr(locale, 'family_code_copy')), findsNothing);
    });

    testWidgets('redeem sheet explains a used code ($locale)', (tester) async {
      repo.redeemError = 'family_code_used';
      await pump(tester, locale, const FamilyRedeemSheet());
      expect(tester.takeException(), isNull);

      await tester.enterText(find.byType(TextField), 'family-ab12cd');
      await tester.pump();
      await tester.tap(find.text(tr(locale, 'family_redeem_button')));
      await tester.pump();
      // Let the error border and the button press animation settle.
      await tester.pump(const Duration(milliseconds: 500));

      expect(repo.redeemedCode, 'family-ab12cd');
      expect(find.text(tr(locale, 'family_err_used')), findsOneWidget);
      await shot(tester, '${locale}_redeem_error');
    });
  }
}

class _FakePremiumRepo implements PremiumRepo {
  List<FamilyCode> codes = const [];
  String? redeemError;
  String? redeemedCode;

  @override
  Future<List<FamilyCode>> getFamilyCodes() async => codes;

  @override
  Future<FamilyRedeemResult> redeemFamilyCode(String code) async {
    redeemedCode = code;
    final error = redeemError;
    if (error == null) return const FamilyRedeemResult(ownerName: 'Ali');
    final options = RequestOptions(path: 'billing/family/redeem');
    throw DioException(
      requestOptions: options,
      response: Response(
        requestOptions: options,
        statusCode: 400,
        data: {'error': error},
      ),
    );
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
