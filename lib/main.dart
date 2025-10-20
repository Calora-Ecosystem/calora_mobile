import 'package:auto_route/auto_route.dart';
import 'package:calora/common/di/injection.dart';
import 'package:calora/common/flavor/flavor_config.dart';
import 'package:calora/common/service/pedometer_service.dart';
import 'package:calora/firebase_options.dart';
import 'package:calora/presentation/app/app.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'common/router/app_router.dart';

final GetIt getIt = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await EasyLocalization.ensureInitialized();
  await configureDependencies();

  await FlavorConfig.initialize();
  setupGetIt();
  runApp(App());
}

void setupGetIt() {
  final appRouter = AppRouter();
  getIt.registerSingleton<StackRouter>(appRouter);
}
