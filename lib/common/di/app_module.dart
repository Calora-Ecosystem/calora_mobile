import 'package:alice/alice.dart';
import 'package:alice/model/alice_configuration.dart';
import 'package:alice_dio/alice_dio_adapter.dart';
import 'package:calora/common/di/injection.dart';
import 'package:calora/common/router/app_router.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:country_detector/country_detector.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:rx_shared_preferences/rx_shared_preferences.dart';

@module
abstract class AppModule {
  @lazySingleton
  Logger get logger => Logger();

  @lazySingleton
  Connectivity get connectivity => Connectivity();

  @lazySingleton
  CountryDetector get countryDetector => CountryDetector();

  @lazySingleton
  Alice getAlice(AppRouter appRouter, AliceDioAdapter aliceDioAdapter) {
    final alice = Alice(
      configuration: AliceConfiguration(
        showNotification: kDebugMode,
        showInspectorOnShake: kDebugMode,
      ),
    );
    alice.setNavigatorKey(appRouter.navigatorKey);
    alice.addAdapter(aliceDioAdapter);
    return alice;
  }

  @preResolve
  @lazySingleton
  Future<SharedPreferences> get sharedPreferences => SharedPreferences.getInstance();

  @lazySingleton
  RxSharedPreferences get preferences => RxSharedPreferences(getIt<SharedPreferences>());

  @lazySingleton
  AppRouter get appRouter => AppRouter();

  @lazySingleton
  AliceDioAdapter get aliceDioAdapter => AliceDioAdapter();
}
