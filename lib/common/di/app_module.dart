import 'package:alice/alice.dart';
import 'package:alice/model/alice_configuration.dart';
import 'package:alice_dio/alice_dio_adapter.dart';
import 'package:calora/common/router/app_router.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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
  Alice getAlice(AppRouter appRouter, AliceDioAdapter aliceDioAdapter) {
    final configuration = AliceConfiguration(showNotification: kProfileMode);
    final alice = Alice(configuration: configuration);
    alice.setNavigatorKey(appRouter.navigatorKey);
    alice.addAdapter(aliceDioAdapter);
    return alice;
  }

  @lazySingleton
  RxSharedPreferences get preferences => RxSharedPreferences(SharedPreferences.getInstance());

  @lazySingleton
  AppRouter get appRouter => AppRouter();

  @lazySingleton
  AliceDioAdapter get aliceDioAdapter => AliceDioAdapter();
}
