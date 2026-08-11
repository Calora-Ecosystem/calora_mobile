import 'dart:developer';
import 'dart:io';

import 'package:alice/alice.dart';
import 'package:calora/common/base/step_ledger_db.dart';
import 'package:calora/common/di/injection.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/localization/safe_csv_asset_loader.dart';
import 'package:calora/common/service/background_steps_worker.dart';
import 'package:calora/common/service/facebook_events_service.dart';
import 'package:calora/common/service/notification_service.dart';
import 'package:calora/common/service/revenuecat_service.dart';
import 'package:calora/common/service/sentry_config.dart';
import 'package:calora/domain/model/language/language.dart';
import 'package:calora/firebase_options.dart';
import 'package:calora/presentation/app/app/app.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  log('[BG] Message id: ${message.messageId}');

  if (Platform.isAndroid && message.notification == null) {
    await NotificationService.instance.initForBackground();
    await NotificationService.instance.showBackgroundDataNotification(message);
  }
}

Future<void> main() async {
  await SentryFlutter.init(
    configureSentry,
    appRunner: () async {
      WidgetsFlutterBinding.ensureInitialized();

      await dotenv.load();
      await EasyLocalization.ensureInitialized();

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      await Hive.initFlutter();
      // steps_meta holds main-isolate-only UI flags; steps_ledger is kept
      // open only so the one-time Hive → SQLite migration can read it.
      await Hive.openBox('steps_ledger');
      await Hive.openBox('steps_meta');
      await StepLedgerDb.instance.migrateFromHiveIfNeeded();

      await configureDependencies();

      if (kDebugMode) getIt<Alice>();

      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      await BackgroundStepsWorker.initialize();

      await NotificationService.instance.initForForeground();

      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
      );
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      await getIt<RevenueCatService>().init();

      await FacebookEventsService.instance.init();

      runApp(
        EasyLocalization(
          supportedLocales: Strings.supportedLocales,
          path: Assets.localization.translations,
          assetLoader: SafeCsvAssetLoader(),
          fallbackLocale: Language.UZ.locale,
          startLocale: Language.UZ.locale,
          child: App(),
        ),
      );

      // iOS App Tracking Transparency prompt — must run once the app is
      // active so the Meta SDK can use the IDFA for ad attribution.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FacebookEventsService.instance.requestTracking();
      });
    },
  );
}