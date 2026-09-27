import 'dart:io';

import 'package:calora/common/gen/fonts.gen.dart';
import 'package:calora/common/localization/safe_csv_asset_loader.dart';
import 'package:calora/domain/model/report/weekly_report.dart';
import 'package:calora/domain/repo/report/report_repo.dart';
import 'package:calora/presentation/app/theme/colors.dart';
import 'package:calora/presentation/report/widgets/weekly_report_section.dart';
import 'package:get_it/get_it.dart';
import 'package:calora/presentation/report/weekly_report_story.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// EasyLocalization.ensureInitialized reads the saved locale from it.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';

/// Walks every slide of the weekly report story on a small phone with the real
/// Uzbek / Russian strings — any overflow or layout error fails the test.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final byLocale = <String, Map<String, dynamic>>{};

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();

    // Parse with the app's own loader, then serve synchronously from memory.
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

  final days = [
    for (var i = 0; i < 7; i++)
      WeeklyReportDay(
        date: DateTime(2026, 9, 14 + i),
        kcal: [1850, 2100, 1720, 2400, 1900, 2650, 0][i].toDouble(),
        protein: 90,
        water: <double>[2, 2.5, 1.5, 2, 2.25, 1, 0][i],
        steps: [8200, 10400, 6100, 12800, 9000, 4300, 1600][i].toDouble(),
        mealCount: i == 6 ? 0 : 4,
        inNorm: [true, true, true, false, true, false, false][i],
      ),
  ];

  final full = WeeklyReport(
    name: 'Saeed',
    weekStart: DateTime(2026, 9, 14),
    weekEnd: DateTime(2026, 9, 20),
    loggedDays: 6,
    daysInNorm: 4,
    norms: const WeeklyReportNorms(
      kcal: 2000,
      protein: 100,
      water: 2,
      step: 8000,
    ),
    days: days,
    totals: const WeeklyReportTotals(
      kcal: 12620,
      steps: 52400,
      water: 12.25,
      mealCount: 23,
    ),
    averages: const WeeklyReportTotals(kcal: 2103, steps: 7486),
    kcalByMenu: const {
      'Breakfast': 2500,
      'Lunch': 4400,
      'Dinner': 4800,
      'Snack': 920,
    },
    topFood: const WeeklyTopFood(name: 'Palov (toʻy oshi)', count: 3),
    heaviestDay: DateTime(2026, 9, 19),
    mostActiveDay: DateTime(2026, 9, 17),
    coinsEarned: 52,
    streak: 12,
    kcalAvgChangePercent: -8.4,
    stepsChangePercent: 15.2,
    badges: const ['perfect_week', 'step_master', 'hydrated'],
    stepDaysInNorm: 4,
    waterDaysInNorm: 5,
    body: const WeeklyBody(
      weight: 81.4,
      entryWeight: 86,
      targetWeight: 75,
      height: 178,
      bmi: 25.7,
    ),
    coins: const WeeklyCoins(
      steps: 52,
      referral: 50,
      earned: 102,
      balance: 340,
    ),
    course: const WeeklyCourse(lessons: 3, workouts: 2),
    friendsInvited: 1,
    stepGroups: 2,
  );

  // A week with steps and coins but no food at all — used to get no report.
  final stepsOnly = WeeklyReport(
    name: 'Saeed',
    weekStart: DateTime(2026, 9, 14),
    weekEnd: DateTime(2026, 9, 20),
    norms: const WeeklyReportNorms(kcal: 2000, water: 2, step: 8000),
    days: [
      for (var i = 0; i < 7; i++)
        WeeklyReportDay(
          date: DateTime(2026, 9, 14 + i),
          steps: [6400, 9100, 0, 11200, 8300, 3900, 7000][i].toDouble(),
        ),
    ],
    totals: const WeeklyReportTotals(steps: 45900),
    averages: const WeeklyReportTotals(steps: 6557),
    mostActiveDay: DateTime(2026, 9, 17),
    coinsEarned: 45,
    stepDaysInNorm: 3,
    body: const WeeklyBody(weight: 80, entryWeight: 84, targetWeight: 75),
    coins: const WeeklyCoins(steps: 45, earned: 45, balance: 120),
  );

  setUpAll(() {
    GetIt.instance
      ..registerSingleton(DefaultThemeColors())
      ..registerSingleton<ReportRepo>(_FakeRepo(() => full));
  });

  Future<void> pumpStory(
    WidgetTester tester,
    WeeklyReport report,
    String locale, {
    Widget? home,
  }) async {
    tester.view.physicalSize = const Size(360 * 3, 640 * 3);
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
              home: home ?? WeeklyReportStory(report: report),
            ),
          ),
        ),
      );
      // The CSV loads asynchronously; EasyLocalization shows nothing until then.
      for (
        var i = 0;
        i < 50 && find.byType(WeeklyReportStory).evaluate().isEmpty;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pump();
      }
    });
    // Not pumpAndSettle — the slide timer would run the story to its end.
    await tester.pump();
  }

  Future<void> walk(WidgetTester tester, int slides, String name) async {
    for (var i = 0; i < slides; i++) {
      await tester.pump(const Duration(milliseconds: 1500));
      expect(tester.takeException(), isNull, reason: '$name slide $i');
      if (const bool.fromEnvironment('WR_GOLDEN')) {
        await expectLater(
          find.byType(WeeklyReportStory),
          matchesGoldenFile('goldens/${name}_$i.png'),
        );
      }
      if (i < slides - 1) {
        await tester.tapAt(const Offset(330, 320));
        await tester.pump(const Duration(milliseconds: 500));
      }
    }
  }

  for (final locale in ['uz_UZ', 'ru_RU']) {
    testWidgets('full report lays out ($locale)', (tester) async {
      await pumpStory(tester, full, locale);
      await walk(tester, 7, 'full_$locale');
    });
  }

  for (final locale in ['uz_UZ', 'ru_RU']) {
    testWidgets('steps-only week still gets a report ($locale)', (
      tester,
    ) async {
      expect(stepsOnly.isEmpty, isFalse);
      // intro, activity, you, share — no empty food slides.
      await pumpStory(tester, stepsOnly, locale);
      await walk(tester, 4, 'steps_$locale');
      expect(find.byType(WeeklyReportStory), findsOneWidget);
    });
  }

  test('a week with nothing recorded is empty', () {
    final empty = WeeklyReport(
      name: '',
      weekStart: full.weekStart,
      weekEnd: full.weekEnd,
      days: [
        for (var i = 0; i < 7; i++)
          WeeklyReportDay(date: DateTime(2026, 9, 14 + i)),
      ],
    );
    expect(empty.isEmpty, isTrue);
    expect(full.isEmpty, isFalse);
  });

  test('unsynced device steps fill in the server numbers', () {
    final merged = stepsOnly.mergeLocalSteps({
      DateTime(2026, 9, 16): 5000, // server had 0
      DateTime(2026, 9, 17): 100, // lower than the server — ignored
    });
    expect(merged.days[2].steps, 5000);
    expect(merged.days[3].steps, 11200);
    expect(merged.totals.steps, 50900);
    expect(merged.activeDays, 7);
    expect(merged.stepDaysInNorm, 3);
    expect(identical(stepsOnly.mergeLocalSteps({}), stepsOnly), isTrue);
  });

  testWidgets('profile section shows last week and opens the story', (
    tester,
  ) async {
    await pumpStory(
      tester,
      full,
      'uz_UZ',
      home: const Scaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: WeeklyReportSection(),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    if (const bool.fromEnvironment('WR_GOLDEN')) {
      await expectLater(
        find.byType(WeeklyReportSection),
        matchesGoldenFile('goldens/section.png'),
      );
    }

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(WeeklyReportStory), findsOneWidget);
  });
}

class _MapLoader extends AssetLoader {
  final Map<String, dynamic> map;

  const _MapLoader(this.map);

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => map;
}

class _FakeRepo implements ReportRepo {
  final WeeklyReport Function() report;

  _FakeRepo(this.report);

  @override
  Future<WeeklyReport> getWeekly(DateTime weekStart) async => report();
}
