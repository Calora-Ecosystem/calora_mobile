import 'package:calora/common/di/injection.dart';
import 'package:calora/common/flavor/flavor_config.dart';
import 'package:calora/firebase_options.dart';
import 'package:calora/presentation/app/app.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await EasyLocalization.ensureInitialized();
  await configureDependencies();

  await FlavorConfig.initialize();

  runApp(App());
}
