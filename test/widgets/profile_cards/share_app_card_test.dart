import 'dart:io';

import 'package:calora/common/constants/app_links.dart';
import 'package:calora/common/gen/fonts.gen.dart';
import 'package:calora/common/localization/safe_csv_asset_loader.dart';
import 'package:calora/presentation/app/theme/colors.dart';
import 'package:calora/widgets/profile_cards/share_app_card.dart';
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
  final shareCalls = <MethodCall>[];

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

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/share'),
          (call) async {
            shareCalls.add(call);
            return null;
          },
        );
  });

  setUp(shareCalls.clear);

  final loaders = <String, _MapLoader>{};

  Widget app(String locale) {
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
            body: const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: ShareAppCard(),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> pump(WidgetTester tester, String locale) async {
    tester.view.physicalSize = const Size(375 * 3, 120 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.runAsync(() async {
      await tester.pumpWidget(app(locale));
      for (
        var i = 0;
        i < 50 && find.byType(ShareAppCard).evaluate().isEmpty;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pump();
      }
      // Let the trailing SVG arrow finish loading before the golden shot.
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump(const Duration(seconds: 1));
  }

  const titles = {
    'uz_UZ': 'Ilovani ulashish',
    'ru_RU': 'Поделиться приложением',
  };

  for (final locale in titles.keys) {
    testWidgets('shows the title and the link ($locale)', (tester) async {
      await pump(tester, locale);
      expect(find.text(titles[locale]!), findsOneWidget);
      expect(find.text('calora.uz/get-app'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (const bool.fromEnvironment('TF_GOLDEN')) {
        await expectLater(
          find.byType(Scaffold),
          matchesGoldenFile('goldens/share_app_$locale.png'),
        );
      }
    });
  }

  testWidgets('tapping shares the download link and nothing else', (
    tester,
  ) async {
    await pump(tester, 'uz_UZ');
    await tester.tap(find.byType(ShareAppCard));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    expect(shareCalls, hasLength(1));
    final args = Map<String, dynamic>.from(shareCalls.single.arguments as Map);
    expect(args['uri'], appDownloadLink);
    expect(args.containsKey('text'), isFalse);
    expect(args.containsKey('paths'), isFalse);
  });
}

class _MapLoader extends AssetLoader {
  final Map<String, dynamic> map;

  const _MapLoader(this.map);

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => map;
}
