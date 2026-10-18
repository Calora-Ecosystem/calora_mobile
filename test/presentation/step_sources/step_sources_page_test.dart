import 'dart:io';

import 'package:calora/common/gen/fonts.gen.dart';
import 'package:calora/common/localization/safe_csv_asset_loader.dart';
import 'package:calora/common/service/pedometer_service.dart';
import 'package:calora/common/service/step_counter_service.dart';
import 'package:calora/domain/repo/step/step_repo.dart';
import 'package:calora/presentation/app/theme/colors.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/dashboard/widgets/battery_optimization_dialog.dart';
import 'package:calora/presentation/dashboard/widgets/health_sync_fix_dialog.dart';
import 'package:calora/presentation/dashboard/widgets/step_tracker_connect_sheet.dart';
import 'package:calora/presentation/step_sources/step_sources_controller.dart';
import 'package:calora/presentation/step_sources/step_sources_page.dart';
import 'package:calora_steps/calora_steps.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';

const _samsung = TrackerAppStatus(
  id: 'samsung_health',
  name: 'Samsung Health',
  packageName: 'com.sec.android.app.shealth',
  syncing: true,
);

const _fit = TrackerAppStatus(
  id: 'google_fit',
  name: 'Google Fit',
  packageName: 'com.google.android.apps.fitness',
  syncing: false,
);

const _healthy = StepTrackingStatus(
  activityRecognition: true,
  notifications: true,
  batteryUnrestricted: true,
  autoStartScreen: true,
  sensorAvailable: true,
  recordingAvailable: true,
  healthConnect: HealthConnectAvailability.available,
  healthConnectConnected: true,
  healthConnectBackgroundAvailable: true,
  healthConnectBackgroundGranted: true,
  trackers: [_samsung, _fit],
  enabled: true,
  serviceRunning: true,
  manufacturer: 'xiaomi',
);

const _broken = StepTrackingStatus(
  sensorAvailable: true,
  recordingAvailable: true,
  healthConnect: HealthConnectAvailability.notInstalled,
  trackers: [
    TrackerAppStatus(
      id: 'mi_fitness',
      name: 'Mi Fitness',
      packageName: 'com.xiaomi.wearable',
      syncing: false,
    ),
  ],
  enabled: true,
  manufacturer: 'samsung',
);

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

    final materialFonts =
        '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts';
    for (final (family, files) in [
      ('MaterialIcons', ['MaterialIcons-Regular.otf']),
      ('Roboto', ['Roboto-Regular.ttf', 'Roboto-Medium.ttf']),
    ]) {
      final loader = FontLoader(family);
      for (final name in files) {
        final file = File('$materialFonts/$name');
        if (file.existsSync()) {
          loader.addFont(
            Future.value(ByteData.sublistView(file.readAsBytesSync())),
          );
        }
      }
      await loader.load();
    }
  });

  Future<void> pump(
    WidgetTester tester,
    String locale,
    Widget home, {
    double height = 740,
  }) async {
    tester.view.physicalSize = Size(360 * 3, height * 3);
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
              debugShowCheckedModeBanner: false,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              theme: context.theme,
              home: home,
            ),
          ),
        ),
      );
      for (var i = 0; i < 50 && find.byWidget(home).evaluate().isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pump();
      }
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> shot(WidgetTester tester, Finder target, String name) async {
    expect(tester.takeException(), isNull, reason: name);
    if (const bool.fromEnvironment('TF_GOLDEN')) {
      await expectLater(target, matchesGoldenFile('goldens/$name.png'));
    }
  }

  testWidgets('healthy setup shows every source as working (ru_RU)', (
    tester,
  ) async {
    final page = StepSourcesPage(
      controller: _FakeController(
        status: _healthy,
        snapshot: const StepSnapshot(
          day: '2026-10-17',
          steps: 8412,
          sensorSteps: 7980,
          healthConnectSteps: 8412,
          recordingSteps: 7950,
          source: StepSourceKind.healthConnect,
          enabled: true,
          serviceRunning: true,
          sensorListening: true,
        ),
      ),
    );
    await pump(tester, 'ru_RU', page, height: 1720);
    expect(find.text('Шаги считаются автоматически'), findsOneWidget);
    expect(find.text('Синхронизируется через Health Connect'), findsOneWidget);
    expect(find.text('Пока не передаёт шаги в Health Connect'), findsOneWidget);
    await shot(tester, find.byType(StepSourcesPage), 'sources_ru_RU_healthy');
  });

  testWidgets('broken setup explains what to fix (uz_UZ)', (tester) async {
    final page = StepSourcesPage(
      controller: _FakeController(
        status: _broken,
        snapshot: const StepSnapshot(
          day: '2026-10-17',
          steps: 0,
          enabled: true,
          issue: StepIssue.activityPermission,
        ),
      ),
    );
    await pump(tester, 'uz_UZ', page, height: 1500);
    expect(find.text('Qadamlar hisoblanmayapti'), findsOneWidget);
    expect(find.text('Health Connect oʻrnatilmagan'), findsOneWidget);
    expect(find.text('Oʻrnatish'), findsOneWidget);
    await shot(tester, find.byType(StepSourcesPage), 'sources_uz_UZ_broken');
  });

  for (final locale in ['uz_UZ', 'ru_RU']) {
    testWidgets('connect offer lays out ($locale)', (tester) async {
      final sheet = Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: StepTrackerConnectSheet(
              tracker: _samsung,
              availability: HealthConnectAvailability.available,
            ),
          ),
        ),
      );
      await pump(tester, locale, sheet);
      await shot(tester, find.byType(Scaffold), 'connect_$locale');
    });

    testWidgets('sync guide lays out ($locale)', (tester) async {
      final dialog = Scaffold(
        body: HealthSyncFixDialog(tracker: _fit, onOpenTracker: () {}),
      );
      await pump(tester, locale, dialog);
      await shot(tester, find.byType(Scaffold), 'syncfix_$locale');
    });

    testWidgets('battery prompt lays out ($locale)', (tester) async {
      const dialog = Scaffold(body: BatteryOptimizationDialog());
      await pump(tester, locale, dialog);
      await shot(tester, find.byType(Scaffold), 'battery_$locale');
    });
  }
}

class _FakeController extends StepSourcesController {
  _FakeController({
    required StepTrackingStatus status,
    required StepSnapshot snapshot,
  }) : super(StepCounterService(_FakeStepRepo(), PedometerService())) {
    this.status = status;
    this.snapshot = snapshot;
    loading = false;
  }

  @override
  Future<void> init() async {}

  @override
  Future<void> reload() async {}

  @override
  Future<void> refreshAll() async {}
}

class _FakeStepRepo extends Fake implements StepRepo {}

class _MapLoader extends AssetLoader {
  const _MapLoader(this.map);

  final Map<String, dynamic> map;

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => map;
}
